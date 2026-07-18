require "test_helper"

# End-to-end OAuth flow as claude.ai performs it: dynamic client registration,
# PKCE authorize (via owner login), code exchange, then calling /mcp with the
# issued token. Guards the full Doorkeeper wiring (e.g. resource owner must
# respond to #id — a bare integer breaks grant creation).
class OauthAuthorizationFlowTest < ActionDispatch::IntegrationTest
  CALLBACK = "https://claude.ai/api/mcp/auth_callback".freeze

  def with_owner_password(value)
    original = ENV["MCP_OWNER_PASSWORD"]
    ENV["MCP_OWNER_PASSWORD"] = value
    yield
  ensure
    original.nil? ? ENV.delete("MCP_OWNER_PASSWORD") : ENV["MCP_OWNER_PASSWORD"] = original
  end

  # claude.ai sends NO scope parameter at register or authorize time; Doorkeeper
  # must fall back to the configured default_scopes instead of erroring with
  # "Missing required parameter: scope".
  test "authorize without a scope param falls back to the default scope" do
    with_owner_password("owner-secret") do
      post "/oauth/register",
           params: { client_name: "Claude", redirect_uris: [ CALLBACK ] }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
      assert_response :created
      client_id = JSON.parse(response.body)["client_id"]

      verifier = SecureRandom.urlsafe_base64(48)
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)

      post "/owner/login", params: { password: "owner-secret", return_to: "/" }

      get "/oauth/authorize", params: {
        client_id: client_id,
        redirect_uri: CALLBACK,
        response_type: "code",
        state: "st456",
        code_challenge: challenge,
        code_challenge_method: "S256"
      }
      assert_response :redirect
      assert response.location.start_with?(CALLBACK), "expected redirect to claude.ai, got #{response.location}"
      code = Rack::Utils.parse_query(URI.parse(response.location).query)["code"]

      post "/oauth/token", params: {
        grant_type: "authorization_code",
        code: code,
        redirect_uri: CALLBACK,
        client_id: client_id,
        code_verifier: verifier
      }
      assert_response :success
      token = JSON.parse(response.body)
      assert_equal "mcp", token["scope"]

      post "/mcp",
           params: { jsonrpc: "2.0", method: "ping", id: 1 }.to_json,
           headers: { "CONTENT_TYPE" => "application/json",
                      "Authorization" => "Bearer #{token["access_token"]}" }
      assert_response :success
    end
  end

  test "full claude.ai-style flow: register, login, authorize, exchange, call mcp" do
    with_owner_password("owner-secret") do
      # 1. Dynamic Client Registration
      post "/oauth/register",
           params: { client_name: "Claude", redirect_uris: [ CALLBACK ], scope: "claudeai" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
      assert_response :created
      client_id = JSON.parse(response.body)["client_id"]

      # 2. PKCE pair
      verifier = SecureRandom.urlsafe_base64(48)
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
      authorize_params = {
        client_id: client_id,
        redirect_uri: CALLBACK,
        response_type: "code",
        scope: "claudeai",
        state: "st123",
        code_challenge: challenge,
        code_challenge_method: "S256"
      }

      # 3. Unauthenticated authorize bounces to the owner login page
      get "/oauth/authorize", params: authorize_params
      assert_response :redirect
      assert_match %r{/owner/login}, response.location

      # 4. Owner logs in; skip_authorization redirects straight back to claude.ai
      post "/owner/login", params: { password: "owner-secret", return_to: "/" }
      assert_response :redirect

      get "/oauth/authorize", params: authorize_params
      assert_response :redirect
      assert response.location.start_with?(CALLBACK), "expected redirect to claude.ai, got #{response.location}"
      query = Rack::Utils.parse_query(URI.parse(response.location).query)
      assert_equal "st123", query["state"]
      code = query["code"]
      assert code.present?

      # 5. Token exchange (public client, PKCE verifier, no secret)
      post "/oauth/token", params: {
        grant_type: "authorization_code",
        code: code,
        redirect_uri: CALLBACK,
        client_id: client_id,
        code_verifier: verifier
      }
      assert_response :success
      token = JSON.parse(response.body)
      assert token["access_token"].present?
      assert token["refresh_token"].present?
      assert_equal "claudeai", token["scope"]

      # 6. The issued token authenticates against /mcp
      post "/mcp",
           params: { jsonrpc: "2.0", method: "ping", id: 1 }.to_json,
           headers: { "CONTENT_TYPE" => "application/json",
                      "Authorization" => "Bearer #{token["access_token"]}" }
      assert_response :success
    end
  end
end
