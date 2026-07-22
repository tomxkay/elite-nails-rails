require "test_helper"

# The owner analytics opt-out toggle (see docs/analytics-plan.md).
class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
       "(KHTML, like Gecko) Chrome/120.0 Safari/537.36".freeze

  test "opt-out sets a persistent cookie and confirms" do
    get analytics_opt_out_path
    assert_response :success
    assert_match(/excluded from analytics/i, response.body)
    assert_equal "1", cookies[:analytics_opt_out]
  end

  test "opt-in clears the cookie and confirms" do
    get analytics_opt_out_path
    assert_equal "1", cookies[:analytics_opt_out]

    get analytics_opt_in_path
    assert_response :success
    assert_match(/re-enabled/i, response.body)
    assert cookies[:analytics_opt_out].blank?
  end

  test "the opt-out page itself is not tracked" do
    assert_no_difference -> { Ahoy::Event.count } do
      get analytics_opt_out_path, headers: { "User-Agent" => UA }
    end
  end

  test "page views stop being recorded after opting out" do
    # A normal visit is tracked...
    assert_difference -> { Ahoy::Event.where(name: "page_viewed").count }, 1 do
      get root_path, headers: { "User-Agent" => UA }
    end

    get analytics_opt_out_path, headers: { "User-Agent" => UA }

    # ...but not once the browser has opted out.
    assert_no_difference -> { Ahoy::Event.where(name: "page_viewed").count } do
      get root_path, headers: { "User-Agent" => UA }
    end
  end

  test "opting back in resumes page-view tracking" do
    get analytics_opt_out_path, headers: { "User-Agent" => UA }
    get analytics_opt_in_path, headers: { "User-Agent" => UA }

    assert_difference -> { Ahoy::Event.where(name: "page_viewed").count }, 1 do
      get root_path, headers: { "User-Agent" => UA }
    end
  end
end
