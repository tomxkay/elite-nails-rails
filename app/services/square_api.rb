# frozen_string_literal: true

require "net/http"

# Thin client for the Square REST API (Catalog/Bookings/Customers), used by the
# native booking flow (BookingsController). Own-seller integration: a single
# access token, no OAuth. Env: SQUARE_ACCESS_TOKEN, SQUARE_LOCATION_ID,
# SQUARE_ENVIRONMENT ("production" or anything else = sandbox).
class SquareApi
  class Error < StandardError; end

  API_VERSION = "2025-01-23"
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 15

  class << self
    def configured?
      ENV["SQUARE_ACCESS_TOKEN"].present? && ENV["SQUARE_LOCATION_ID"].present?
    end

    def location_id
      ENV["SQUARE_LOCATION_ID"]
    end

    def base_url
      if ENV["SQUARE_ENVIRONMENT"].to_s == "production"
        "https://connect.squareup.com"
      else
        "https://connect.squareupsandbox.com"
      end
    end

    # Bookable services (catalog items with product_type APPOINTMENTS_SERVICE).
    # => [{ id:, version:, name:, price:, duration_minutes: }] — id/version are
    # the service *variation*'s, which is what bookings reference.
    def services
      data = post("/v2/catalog/search", { object_types: [ "ITEM" ] })
      (data["objects"] || []).filter_map do |item|
        item_data = item["item_data"] || {}
        next unless item_data["product_type"] == "APPOINTMENTS_SERVICE"

        variation = (item_data["variations"] || []).first
        next unless variation

        vdata = variation["item_variation_data"] || {}
        {
          id: variation["id"],
          version: variation["version"],
          name: item_data["name"],
          price: format_money(vdata["price_money"]),
          duration_minutes: (vdata["service_duration"] || 0) / 60_000
        }
      end
    end

    # Staff who can be booked for appointments. => [{ id:, name: }]
    def bookable_staff
      data = get("/v2/bookings/team-member-booking-profiles", bookable_only: "true")
      (data["team_member_booking_profiles"] || []).map do |profile|
        { id: profile["team_member_id"], name: profile["display_name"] }
      end
    end

    # Open slots for a service (optionally limited to one tech).
    # => [{ start_at:, team_member_id:, service_variation_version: }]
    def availability(service_variation_id:, start_at:, end_at:, team_member_id: nil)
      segment = { service_variation_id: service_variation_id }
      segment[:team_member_id_filter] = { any: [ team_member_id ] } if team_member_id

      data = post("/v2/bookings/availability/search", {
        query: {
          filter: {
            start_at_range: { start_at: start_at.iso8601, end_at: end_at.iso8601 },
            location_id: location_id,
            segment_filters: [ segment ]
          }
        }
      })
      (data["availabilities"] || []).map do |slot|
        seg = (slot["appointment_segments"] || []).first || {}
        {
          start_at: slot["start_at"],
          team_member_id: seg["team_member_id"],
          service_variation_version: seg["service_variation_version"]
        }
      end
    end

    # Find a customer by exact phone/email, or create one.
    def upsert_customer(given_name:, phone:, email: nil)
      found = search_customer(phone: phone, email: email)
      return found if found

      data = post("/v2/customers", {
        idempotency_key: SecureRandom.uuid,
        given_name: given_name,
        phone_number: phone,
        email_address: email
      }.compact)
      data["customer"]
    end

    def create_booking(customer_id:, start_at:, service_variation_id:, service_variation_version:,
                       team_member_id:, note: nil)
      data = post("/v2/bookings", {
        idempotency_key: SecureRandom.uuid,
        booking: {
          location_id: location_id,
          start_at: start_at,
          customer_id: customer_id,
          customer_note: note,
          appointment_segments: [ {
            service_variation_id: service_variation_id,
            service_variation_version: service_variation_version.to_i,
            team_member_id: team_member_id
          } ]
        }.compact
      })
      data["booking"]
    end

    private

    def search_customer(phone:, email: nil)
      filter =
        if email.present?
          { email_address: { exact: email } }
        else
          { phone_number: { exact: phone } }
        end
      data = post("/v2/customers/search", { query: { filter: filter }, limit: 1 })
      (data["customers"] || []).first
    rescue Error
      # A malformed filter (e.g. unusual phone format) shouldn't sink the
      # booking — fall through to creating a fresh customer.
      nil
    end

    def get(path, params = {})
      uri_path = params.any? ? "#{path}?#{params.to_query}" : path
      request(Net::HTTP::Get.new(full_uri(uri_path)))
    end

    def post(path, body)
      req = Net::HTTP::Post.new(full_uri(path))
      req.body = JSON.generate(body)
      request(req)
    end

    def full_uri(path)
      URI("#{base_url}#{path}")
    end

    def request(req)
      raise Error, "Square is not configured (missing env vars)" unless configured?

      req["Authorization"] = "Bearer #{ENV['SQUARE_ACCESS_TOKEN']}"
      req["Square-Version"] = API_VERSION
      req["Content-Type"] = "application/json"

      uri = req.uri
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      response = http.request(req)
      json = JSON.parse(response.body.presence || "{}") rescue {}
      unless response.is_a?(Net::HTTPSuccess)
        detail = json.dig("errors", 0, "detail") || json.dig("errors", 0, "code")
        raise Error, detail || "Square API error (HTTP #{response.code})"
      end
      json
    rescue Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
      raise Error, "Could not reach Square (#{e.class.name.demodulize})"
    end

    def format_money(money)
      return nil unless money&.dig("amount")

      dollars = money["amount"] / 100.0
      (dollars % 1).zero? ? "$#{dollars.to_i}" : format("$%.2f", dollars)
    end
  end
end
