require "test_helper"
require "minitest/mock"

# The native booking flow (Phase D2). SquareApi is stubbed — no HTTP leaves the
# test suite.
class BookingsControllerTest < ActionDispatch::IntegrationTest
  SERVICES = [ { id: "VAR1", version: 7, name: "Gel Manicure", price: "$40", duration_minutes: 45 } ].freeze
  STAFF = [ { id: "TM1", name: "Michael K" } ].freeze
  SLOTS = [ { start_at: "2026-07-20T14:00:00Z", team_member_id: "TM1", service_variation_version: 7 } ].freeze
  # Ahoy skips bot/blank-UA traffic, so event-tracking tests send a browser UA.
  BROWSER_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
               "(KHTML, like Gecko) Chrome/120.0 Safari/537.36".freeze

  test "show backfills a missing Square description from the site menu" do
    PricingItem.create!(category: "Manicures", name: "Gel Manicure", price: "$40",
                        description: "Cured to a high shine that resists chips.")

    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path
        end
      end
    end

    assert_response :success
    assert_match "Cured to a high shine that resists chips.", response.body
  end

  test "show prefers Square's own description over the site menu" do
    PricingItem.create!(category: "Manicures", name: "Gel Manicure", price: "$40",
                        description: "Site copy that should lose.")
    from_square = [ SERVICES.first.merge(description: "Square copy that should win.") ]

    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, from_square) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path
        end
      end
    end

    assert_response :success
    assert_match "Square copy that should win.", response.body
    assert_no_match "Site copy that should lose.", response.body
  end

  test "show renders the wizard with services and staff" do
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path
        end
      end
    end
    assert_response :success
    assert_match "Gel Manicure", response.body
    assert_match "Michael K", response.body
    assert_select "main.page-with-fixed-header-offset"
    assert_select "header a[href='#home']", count: 0
    assert_select "header a[href='/#services']"
    assert_select "header a[href='/']"
    assert_select "footer a[href='/#pricing']"
  end

  test "show honors availability preselection" do
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path, params: { service_id: "VAR1", team_member_id: "TM1", date: (Date.current + 2).iso8601 }
        end
      end
    end
    assert_response :success
    assert_select "input[data-booking-target='service'][checked]"
    assert_select "option[value='TM1'][selected]"
    assert_select "input[data-booking-target='date'][value=?]", (Date.current + 2).iso8601
  end

  test "show renders the service search filter only when the list is long" do
    many = (1..8).map { |i| { id: "VAR#{i}", version: 1, name: "Service #{i}", price: "$10", duration_minutes: 30 } }
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, many) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path
        end
      end
    end
    assert_response :success
    assert_select "input[data-booking-target='serviceFilter']"

    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path
        end
      end
    end
    assert_select "input[data-booking-target='serviceFilter']", count: 0
  end

  test "show preselects a catalog service matched loosely from a marketing name" do
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          # "Manicures" (home-page card title) → "Gel Manicure" (catalog name).
          get book_path, params: { service_name: "Manicures" }
        end
      end
    end
    assert_response :success
    assert_select "input[data-booking-target='service'][value='VAR1'][checked]"
  end

  test "show leaves the wizard unselected for an unmatched service name" do
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path, params: { service_name: "Waxing Services" }
        end
      end
    end
    assert_response :success
    assert_select "input[data-booking-target='service'][checked]", count: 0
  end

  test "show redirects to BOOKING_URL when square is not configured" do
    original = ENV["BOOKING_URL"]
    ENV["BOOKING_URL"] = "https://square.example/book"
    SquareApi.stub(:configured?, false) do
      get book_path
    end
    assert_redirected_to "https://square.example/book"
  ensure
    original.nil? ? ENV.delete("BOOKING_URL") : ENV["BOOKING_URL"] = original
  end

  test "show degrades to the phone fallback panel on a square error" do
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, -> { raise SquareApi::Error, "down" }) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get book_path
        end
      end
    end
    assert_response :success
    assert_match "call us", response.body.downcase
  end

  test "availability returns slots as json" do
    SquareApi.stub(:availability, SLOTS) do
      get "/book/availability", params: { service_id: "VAR1", date: "2026-07-20" }
    end
    assert_response :success
    assert_equal "2026-07-20T14:00:00Z", JSON.parse(response.body).dig("slots", 0, "start_at")
  end

  test "availability without a service is a 422" do
    get "/book/availability", params: { date: "2026-07-20" }
    assert_response :unprocessable_entity
  end

  test "availability options returns square services and staff" do
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          get "/book/availability/options"
        end
      end
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Gel Manicure", body.dig("services", 0, "name")
    assert_equal "Michael K", body.dig("staff", 0, "name")
  end

  test "availability options reports when square is unavailable" do
    SquareApi.stub(:configured?, false) do
      get "/book/availability/options"
    end
    assert_response :service_unavailable
  end

  test "next availability groups the earliest slot by technician" do
    date = Date.current + 1
    slots = [
      { start_at: (date + 1).in_time_zone.change(hour: 14).iso8601, team_member_id: "TM1", service_variation_version: 7 },
      { start_at: date.in_time_zone.change(hour: 15).iso8601, team_member_id: "TM1", service_variation_version: 7 },
      { start_at: date.in_time_zone.change(hour: 11).iso8601, team_member_id: "TM2", service_variation_version: 7 }
    ]
    staff = [ { id: "TM1", name: "Michael K" }, { id: "TM2", name: "Nhan Ka" } ]

    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:availability, slots) do
        SquareApi.stub(:bookable_staff, staff) do
          get "/book/availability/next", params: { service_id: "VAR1", date: date.iso8601, days: 14 }
        end
      end
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal date.in_time_zone.change(hour: 15).iso8601, body.dig("technicians", 0, "next_slot", "start_at")
    assert_equal date.in_time_zone.change(hour: 11).iso8601, body.dig("technicians", 1, "next_slot", "start_at")
    assert_equal date.in_time_zone.change(hour: 11).iso8601, body.dig("anyone_next_slot", "start_at")
  end

  test "next availability rejects an invalid date" do
    SquareApi.stub(:configured?, true) do
      get "/book/availability/next", params: { service_id: "VAR1", date: "not-a-date" }
    end
    assert_response :unprocessable_entity
  end

  test "create books through square and returns the booking" do
    created = { "id" => "BK1", "start_at" => "2026-07-20T14:00:00Z", "status" => "ACCEPTED" }
    captured = nil
    SquareApi.stub(:upsert_customer, { "id" => "CUST1" }) do
      SquareApi.stub(:create_booking, ->(**args) { captured = args; created }) do
        post book_path, params: {
          service_id: "VAR1", service_version: 7, start_at: "2026-07-20T14:00:00Z",
          team_member_id: "TM1", idempotency_key: "booking-attempt-1", name: "Sarah", phone: "7045551234"
        }, as: :json
      end
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ok"]
    assert_equal "BK1", body.dig("booking", "id")
    assert_equal "booking-attempt-1", captured[:idempotency_key]
  end

  test "create surfaces square errors as 422 with a message" do
    SquareApi.stub(:upsert_customer, { "id" => "CUST1" }) do
      SquareApi.stub(:create_booking, ->(**) { raise SquareApi::Error, "That time is no longer available" }) do
        post book_path, params: {
          service_id: "VAR1", service_version: 7, start_at: "2026-07-20T14:00:00Z",
          team_member_id: "TM1", idempotency_key: "booking-attempt-2", name: "Sarah", phone: "7045551234"
        }, as: :json
      end
    end
    assert_response :unprocessable_entity
    assert_match "no longer available", JSON.parse(response.body)["error"]
  end

  test "create with missing fields is a 422" do
    post book_path, params: { name: "Sarah" }, as: :json
    assert_response :unprocessable_entity
    assert_match "Missing required field", JSON.parse(response.body)["error"]
  end

  test "create rejects a filled honeypot without touching square" do
    SquareApi.stub(:upsert_customer, ->(**) { flunk "bot submission reached Square" }) do
      post book_path, params: valid_booking_params.merge(website: "http://spam.example"), as: :json
    end
    assert_response :unprocessable_entity
    assert_match "call us", JSON.parse(response.body)["error"].downcase
  end

  test "create ignores an empty honeypot" do
    SquareApi.stub(:upsert_customer, { "id" => "CUST1" }) do
      SquareApi.stub(:create_booking, { "id" => "BK1", "start_at" => "2026-07-20T14:00:00Z", "status" => "ACCEPTED" }) do
        post book_path, params: valid_booking_params.merge(website: ""), as: :json
      end
    end
    assert_response :success
    assert JSON.parse(response.body)["ok"]
  end

  test "create is throttled after the per-IP cap" do
    booking = { "id" => "BK1", "start_at" => "2026-07-20T14:00:00Z", "status" => "ACCEPTED" }
    with_counting_cache do
      SquareApi.stub(:upsert_customer, { "id" => "CUST1" }) do
        SquareApi.stub(:create_booking, booking) do
          10.times do |i|
            post book_path, params: valid_booking_params.merge(idempotency_key: "key-#{i}"), as: :json
            assert_response :success
          end
          post book_path, params: valid_booking_params.merge(idempotency_key: "key-over"), as: :json
        end
      end
    end
    assert_response :too_many_requests
    assert_equal "3600", response.headers["Retry-After"]
    assert_match(/wait/i, JSON.parse(response.body)["error"])
  end

  test "availability is throttled after the per-IP cap" do
    with_counting_cache do
      SquareApi.stub(:availability, SLOTS) do
        60.times do
          get "/book/availability", params: { service_id: "VAR1", date: "2026-07-20" }
          assert_response :success
        end
        get "/book/availability", params: { service_id: "VAR1", date: "2026-07-20" }
      end
    end
    assert_response :too_many_requests
  end

  test "throttling fails open when the cache is unavailable" do
    # The test env uses a null cache store whose increment is unsupported; the
    # limiter must swallow that and let every request through.
    booking = { "id" => "BK1", "start_at" => "2026-07-20T14:00:00Z", "status" => "ACCEPTED" }
    SquareApi.stub(:upsert_customer, { "id" => "CUST1" }) do
      SquareApi.stub(:create_booking, booking) do
        20.times do |i|
          post book_path, params: valid_booking_params.merge(idempotency_key: "open-#{i}"), as: :json
          assert_response :success
        end
      end
    end
  end

  test "show tracks a page view and book_page_opened" do
    SquareApi.stub(:configured?, true) do
      SquareApi.stub(:services, SERVICES) do
        SquareApi.stub(:bookable_staff, STAFF) do
          assert_difference -> { Ahoy::Event.where(name: "book_page_opened").count }, 1 do
            get book_path, headers: { "User-Agent" => BROWSER_UA }
          end
        end
      end
    end
    assert Ahoy::Event.where(name: "page_viewed").exists?
    assert_equal 1, Ahoy::Event.find_by(name: "book_page_opened").properties["service_count"]
  end

  test "create tracks booking_submitted and booking_completed without PII" do
    created = { "id" => "BK1", "start_at" => "2026-07-20T14:00:00Z", "status" => "ACCEPTED" }
    SquareApi.stub(:upsert_customer, { "id" => "CUST1" }) do
      SquareApi.stub(:create_booking, created) do
        assert_difference -> { Ahoy::Event.where(name: %w[booking_submitted booking_completed]).count }, 2 do
          post book_path, params: valid_booking_params, as: :json, headers: { "User-Agent" => BROWSER_UA }
        end
      end
    end
    assert_response :success
    completed = Ahoy::Event.find_by(name: "booking_completed")
    assert_equal "VAR1", completed.properties["service_id"]
    assert_equal false, completed.properties["has_email"]
    refute completed.properties.key?("phone"), "must not store PII"
    refute completed.properties.key?("name"), "must not store PII"
  end

  private

  def valid_booking_params
    {
      service_id: "VAR1", service_version: 7, start_at: "2026-07-20T14:00:00Z",
      team_member_id: "TM1", idempotency_key: "booking-attempt", name: "Sarah", phone: "7045551234"
    }
  end

  # Swap in a real counting store so throttle limits actually accumulate (the
  # test env's null store no-ops, which is what "fails open" relies on).
  def with_counting_cache
    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      yield
    end
  end
end
