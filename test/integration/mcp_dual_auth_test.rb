require "test_helper"

# Exercises the McpDualAuth middleware in front of /mcp: static MCP_AUTH_TOKEN
# (Claude Code) or a Doorkeeper access token (claude.ai) must be accepted;
# anything else gets 401 + the RFC 9728 WWW-Authenticate discovery challenge.
class McpDualAuthTest < ActionDispatch::IntegrationTest
  PING = { jsonrpc: "2.0", method: "ping", id: 1 }.to_json

  def post_mcp(token: nil)
    headers = { "CONTENT_TYPE" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token
    post "/mcp/messages", params: PING, headers: headers
  end

  def with_static_token(value)
    original = ENV["MCP_AUTH_TOKEN"]
    value.nil? ? ENV.delete("MCP_AUTH_TOKEN") : ENV["MCP_AUTH_TOKEN"] = value
    yield
  ensure
    original.nil? ? ENV.delete("MCP_AUTH_TOKEN") : ENV["MCP_AUTH_TOKEN"] = original
  end

  def oauth_token(expires_in: 1.hour, revoked: false)
    app = Doorkeeper::Application.create!(
      name: "Claude",
      redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      confidential: false
    )
    token = Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: 1,
      expires_in: expires_in.to_i
    )
    token.revoke if revoked
    token
  end

  test "missing token gets 401 with WWW-Authenticate discovery challenge" do
    with_static_token("static-secret") { post_mcp }

    assert_response :unauthorized
    assert_equal %(Bearer resource_metadata="http://www.example.com/.well-known/oauth-protected-resource"),
                 response.headers["WWW-Authenticate"]
    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
    assert_equal "WWW-Authenticate", response.headers["Access-Control-Expose-Headers"]
    assert_equal(-32_000, JSON.parse(response.body).dig("error", "code"))
  end

  test "wrong token gets 401" do
    with_static_token("static-secret") { post_mcp(token: "not-the-token") }
    assert_response :unauthorized
  end

  test "static MCP_AUTH_TOKEN authenticates" do
    with_static_token("static-secret") { post_mcp(token: "static-secret") }
    assert_response :success
  end

  test "doorkeeper access token authenticates" do
    token = oauth_token
    with_static_token("static-secret") { post_mcp(token: token.token) }
    assert_response :success
  end

  test "doorkeeper token works even when no static token is configured" do
    token = oauth_token
    with_static_token(nil) { post_mcp(token: token.token) }
    assert_response :success
  end

  test "revoked doorkeeper token gets 401" do
    token = oauth_token(revoked: true)
    with_static_token(nil) { post_mcp(token: token.token) }
    assert_response :unauthorized
  end

  test "expired doorkeeper token gets 401" do
    token = oauth_token(expires_in: -1.hour)
    with_static_token(nil) { post_mcp(token: token.token) }
    assert_response :unauthorized
  end

  test "CORS preflight passes through without auth" do
    with_static_token("static-secret") do
      options "/mcp/sse", headers: { "Origin" => "https://claude.ai" }
    end
    assert_response :success
  end

  test "non-mcp routes are unaffected" do
    with_static_token("static-secret") { get "/up" }
    assert_response :success
  end
end
