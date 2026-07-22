require "test_helper"
require "minitest/mock"

# Client-reported KPI events endpoint (see docs/analytics-plan.md).
class EventsControllerTest < ActionDispatch::IntegrationTest
  # Ahoy skips bot/blank-UA traffic, so tracking tests send a browser UA.
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
       "(KHTML, like Gecko) Chrome/120.0 Safari/537.36".freeze

  test "records an allow-listed event with its properties" do
    assert_difference -> { Ahoy::Event.where(name: "phone_click").count }, 1 do
      post "/events",
           params: { name: "phone_click", properties: { href: "tel:+17048249032" } },
           as: :json, headers: { "User-Agent" => UA }
    end
    assert_response :no_content
    assert_equal "tel:+17048249032", Ahoy::Event.order(:id).last.properties["href"]
  end

  test "rejects an event that is not allow-listed" do
    assert_no_difference -> { Ahoy::Event.count } do
      post "/events", params: { name: "booking_completed" }, as: :json, headers: { "User-Agent" => UA }
    end
    assert_response :unprocessable_entity
  end

  test "sanitizes properties to a bounded, flat bag of primitives" do
    post "/events", params: {
      name: "service_selected",
      properties: { service: "a" * 500, count: 3, nested: { x: 1 } }
    }, as: :json, headers: { "User-Agent" => UA }
    assert_response :no_content

    props = Ahoy::Event.order(:id).last.properties
    assert_equal 200, props["service"].length # long string truncated
    assert_equal 3, props["count"]            # numeric preserved
    assert_kind_of String, props["nested"]    # nested structure coerced to string
  end

  test "honors Do Not Track" do
    assert_no_difference -> { Ahoy::Event.count } do
      post "/events", params: { name: "phone_click" }, as: :json,
                      headers: { "User-Agent" => UA, "DNT" => "1" }
    end
    assert_response :no_content
  end

  test "records nothing from a browser that opted out" do
    get analytics_opt_out_path # sets the opt-out cookie on this session
    assert_no_difference -> { Ahoy::Event.count } do
      post "/events", params: { name: "phone_click" }, as: :json, headers: { "User-Agent" => UA }
    end
    assert_response :no_content
  end

  test "is rate limited after the per-IP cap" do
    with_counting_cache do
      120.times do
        post "/events", params: { name: "phone_click" }, as: :json, headers: { "User-Agent" => UA }
        assert_response :no_content
      end
      post "/events", params: { name: "phone_click" }, as: :json, headers: { "User-Agent" => UA }
    end
    assert_response :too_many_requests
  end

  private

  def with_counting_cache
    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) { yield }
  end
end
