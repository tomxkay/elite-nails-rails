module Oauth
  # OAuth 2.1 discovery metadata for the MCP authorization flow.
  #   - /.well-known/oauth-protected-resource   (RFC 9728) — points at the authz server
  #   - /.well-known/oauth-authorization-server  (RFC 8414) — advertises endpoints + PKCE
  # These must be publicly readable (no auth) and CORS-open (claude.ai fetches them
  # from the browser during discovery).
  class MetadataController < ActionController::Base
    before_action :allow_cross_origin

    def protected_resource
      render json: {
        resource: "#{base}/mcp",
        authorization_servers: [base],
        bearer_methods_supported: ["header"],
        resource_documentation: "#{base}/"
      }
    end

    def authorization_server
      render json: {
        issuer: base,
        authorization_endpoint: "#{base}/oauth/authorize",
        token_endpoint: "#{base}/oauth/token",
        registration_endpoint: "#{base}/oauth/register",
        response_types_supported: ["code"],
        grant_types_supported: ["authorization_code", "refresh_token"],
        code_challenge_methods_supported: ["S256"],
        token_endpoint_auth_methods_supported: ["none"]
      }
    end

    private

    def allow_cross_origin
      response.set_header("Access-Control-Allow-Origin", "*")
    end

    # External base URL (works on localhost, ngrok, and Fly).
    def base
      request.base_url
    end
  end
end
