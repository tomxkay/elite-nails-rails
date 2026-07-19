require "test_helper"
require "minitest/mock"

class SquareApiTest < ActiveSupport::TestCase
  CATALOG = {
    "objects" => [
      { "type" => "ITEM", "item_data" => {
        "name" => "Gel Manicure", "product_type" => "APPOINTMENTS_SERVICE",
        "variations" => [ { "id" => "VAR1", "version" => 7, "item_variation_data" => {
          "price_money" => { "amount" => 4000, "currency" => "USD" }, "service_duration" => 2_700_000
        } } ] } },
      { "type" => "ITEM", "item_data" => { "name" => "Gift Card", "product_type" => "REGULAR" } }
    ]
  }.freeze

  test "configured? requires token and location" do
    with_env("SQUARE_ACCESS_TOKEN" => "t", "SQUARE_LOCATION_ID" => "L") do
      assert SquareApi.configured?
    end
    with_env("SQUARE_ACCESS_TOKEN" => nil, "SQUARE_LOCATION_ID" => "L") do
      assert_not SquareApi.configured?
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
      assert_equal({ id: "VAR1", version: 7, name: "Gel Manicure", price: "$40", duration_minutes: 45 },
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
