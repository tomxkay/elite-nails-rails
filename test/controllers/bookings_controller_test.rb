require "test_helper"
require "minitest/mock"

# The native booking flow (Phase D2). SquareApi is stubbed — no HTTP leaves the
# test suite.
class BookingsControllerTest < ActionDispatch::IntegrationTest
  SERVICES = [ { id: "VAR1", version: 7, name: "Gel Manicure", price: "$40", duration_minutes: 45 } ].freeze
  STAFF = [ { id: "TM1", name: "Michael K" } ].freeze
  SLOTS = [ { start_at: "2026-07-20T14:00:00Z", team_member_id: "TM1", service_variation_version: 7 } ].freeze

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
    assert_select "header a[href='/#home']"
    assert_select "footer a[href='/#pricing']"
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
end
