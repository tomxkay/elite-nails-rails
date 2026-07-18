require "test_helper"

class Oauth::RegistrationControllerTest < ActionDispatch::IntegrationTest
  def json_headers
    { "CONTENT_TYPE" => "application/json" }
  end

  test "registers a public client and returns RFC 7591 metadata" do
    assert_difference -> { Doorkeeper::Application.count }, 1 do
      post "/oauth/register",
           params: { client_name: "Claude", redirect_uris: ["https://claude.ai/api/mcp/auth_callback"] }.to_json,
           headers: json_headers
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert body["client_id"].present?
    assert_equal "none", body["token_endpoint_auth_method"]
    assert_equal ["https://claude.ai/api/mcp/auth_callback"], body["redirect_uris"]

    app = Doorkeeper::Application.last
    assert_not app.confidential, "registered client should be public"
  end

  test "requires redirect_uris" do
    post "/oauth/register", params: { client_name: "x" }.to_json, headers: json_headers
    assert_response :bad_request
    assert_equal "invalid_redirect_uri", JSON.parse(response.body)["error"]
  end
end
