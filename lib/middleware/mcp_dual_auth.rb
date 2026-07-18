# frozen_string_literal: true

# Dual-auth guard for the MCP endpoints (/mcp/*). Inserted ahead of fast-mcp's
# transport middleware (see config/initializers/fast_mcp.rb) and owns all MCP
# authentication — fast-mcp's built-in static-token auth is disabled.
#
# Accepts EITHER:
#   - the static bearer token (MCP_AUTH_TOKEN) — used by Claude Code, or
#   - a live Doorkeeper OAuth access token — used by claude.ai connectors.
#
# Anything else gets 401 + a WWW-Authenticate challenge pointing at the
# protected-resource metadata (RFC 9728), which is what triggers an MCP
# client's OAuth discovery flow.
class McpDualAuth
  PATH_PREFIX = "/mcp"

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless mcp_path?(env["PATH_INFO"])

    request = Rack::Request.new(env)
    # CORS preflights never carry Authorization; let the transport answer them.
    return @app.call(env) if request.options?

    token = bearer_token(env)
    return @app.call(env) if static_token_valid?(token) || oauth_token_valid?(token)

    unauthorized_response(request)
  end

  private

  def mcp_path?(path)
    path == PATH_PREFIX || path.to_s.start_with?("#{PATH_PREFIX}/")
  end

  def bearer_token(env)
    header = env["HTTP_AUTHORIZATION"].to_s
    header.delete_prefix("Bearer ").strip.presence if header.start_with?("Bearer ")
  end

  # Read at request time (not boot) so the token can be rotated/varied in tests.
  def static_token_valid?(token)
    static = ENV["MCP_AUTH_TOKEN"].presence
    return false unless static && token

    ActiveSupport::SecurityUtils.secure_compare(token, static)
  end

  def oauth_token_valid?(token)
    return false unless token

    access_token = Doorkeeper::AccessToken.by_token(token)
    access_token.present? && access_token.accessible?
  end

  def unauthorized_response(request)
    metadata_url = "#{request.base_url}/.well-known/oauth-protected-resource"
    body = JSON.generate(
      jsonrpc: "2.0",
      error: { code: -32_000, message: "Unauthorized: valid bearer token required" },
      id: nil
    )
    [
      401,
      {
        "Content-Type" => "application/json",
        "WWW-Authenticate" => %(Bearer resource_metadata="#{metadata_url}"),
        # claude.ai reads the challenge from the browser, so it must be CORS-visible.
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Expose-Headers" => "WWW-Authenticate"
      },
      [ body ]
    ]
  end
end
