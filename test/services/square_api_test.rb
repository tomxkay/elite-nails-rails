require "test_helper"
require "minitest/mock"

class SquareApiTest < ActiveSupport::TestCase
  CATALOG = {
    "objects" => [
      { "type" => "ITEM", "item_data" => {
        "name" => "Gel Manicure", "product_type" => "APPOINTMENTS_SERVICE",
        "description" => "A full manicure finished with gel polish.",
        "variations" => [ { "id" => "VAR1", "version" => 7, "item_variation_data" => {
          "price_money" => { "amount" => 4000, "currency" => "USD" }, "service_duration" => 2_700_000
        } } ] } },
      { "type" => "ITEM", "item_data" => { "name" => "Gift Card", "product_type" => "REGULAR" } }
    ]
  }.freeze

  test "configured? requires a location plus either env token or stored credential" do
    with_env("SQUARE_ACCESS_TOKEN" => "t", "SQUARE_LOCATION_ID" => "L") do
      assert SquareApi.configured?
    end
    with_env("SQUARE_ACCESS_TOKEN" => nil, "SQUARE_LOCATION_ID" => "L") do
      assert_not SquareApi.configured?
      SquareCredential.store_oauth!({ "access_token" => "db-token" }, environment: "sandbox")
      assert SquareApi.configured?
    end
  end

  test "access_token prefers the stored credential and lazily refreshes near expiry" do
    with_env("SQUARE_ACCESS_TOKEN" => "env-token") do
      assert_equal "env-token", SquareApi.access_token

      SquareCredential.store_oauth!(
        { "access_token" => "db-token", "refresh_token" => "r", "expires_at" => 20.days.from_now.iso8601 },
        environment: "sandbox"
      )
      assert_equal "db-token", SquareApi.access_token

      SquareCredential.sole.update!(expires_at: 1.day.from_now)
      renewed = { "access_token" => "renewed-token", "expires_at" => 40.days.from_now.iso8601 }
      SquareApi.stub(:oauth_token, renewed) do
        assert_equal "renewed-token", SquareApi.access_token
      end
    end
  end

  test "access_token falls back to the stale stored token when refresh fails" do
    with_env("SQUARE_ACCESS_TOKEN" => nil) do
      SquareCredential.store_oauth!(
        { "access_token" => "stale-token", "refresh_token" => "r", "expires_at" => 1.day.from_now.iso8601 },
        environment: "sandbox"
      )
      SquareApi.stub(:oauth_token, ->(**) { raise SquareApi::Error, "down" }) do
        assert_equal "stale-token", SquareApi.access_token
      end
    end
  end

  test "base_url follows SQUARE_ENVIRONMENT" do
    with_env("SQUARE_ENVIRONMENT" => "production") do
      assert_equal "https://connect.squareup.com", SquareApi.base_url
    end
    with_env("SQUARE_ENVIRONMENT" => "sandbox") do
      assert_equal "https://connect.squareupsandbox.com", SquareApi.base_url
    end
  end

  test "services keeps only appointment services and formats price/duration" do
    SquareApi.stub(:post, CATALOG) do
      services = SquareApi.services
      assert_equal 1, services.size
      assert_equal({ id: "VAR1", version: 7, name: "Gel Manicure",
                     description: "A full manicure finished with gel polish.",
                     price: "$40", duration_minutes: 45 },
                   services.first)
    end
  end

  test "availability flattens appointment segments" do
    response = { "availabilities" => [
      { "start_at" => "2026-07-20T14:00:00Z",
        "appointment_segments" => [ { "team_member_id" => "TM1", "service_variation_version" => 7 } ] }
    ] }
    SquareApi.stub(:post, response) do
      slots = SquareApi.availability(service_variation_id: "VAR1", start_at: Time.now, end_at: Time.now + 1.day)
      assert_equal [ { start_at: "2026-07-20T14:00:00Z", team_member_id: "TM1", service_variation_version: 7 } ],
                   slots
    end
  end

  private

  def with_env(vars)
    originals = vars.keys.index_with { |k| ENV[k] }
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    originals.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
