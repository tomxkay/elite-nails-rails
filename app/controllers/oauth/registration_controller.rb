module Oauth
  # Dynamic Client Registration (RFC 7591). Doorkeeper doesn't ship this, so we
  # create a public Doorkeeper::Application on the fly and return its client_id.
  # Public + open registration is expected for MCP clients like Claude.
  class RegistrationController < ActionController::Base
    skip_forgery_protection # machine-to-machine JSON API (RFC 7591)
    before_action :allow_cross_origin

    def create
      body = parse_body
      redirect_uris = Array(body["redirect_uris"]).map(&:to_s).reject(&:blank?)

      if redirect_uris.empty?
        return render_error("invalid_redirect_uri", "redirect_uris is required")
      end

      app = Doorkeeper::Application.new(
        name: body["client_name"].presence || "MCP Client",
        redirect_uri: redirect_uris.join("\n"),
        confidential: false, # public client — PKCE, no secret
        # Deliberately blank: per-app scopes would override the server's
        # default/optional scopes at authorize time, and claude.ai omits the
        # scope param there — a stored list would then fail scope validation.
        scopes: ""
      )

      if app.save
        render json: registration_response(app, redirect_uris), status: :created
      else
        render_error("invalid_client_metadata", app.errors.full_messages.join(", "))
      end
    end

    private

    def registration_response(app, redirect_uris)
      {
        client_id: app.uid,
        client_id_issued_at: app.created_at.to_i,
        client_name: app.name,
        redirect_uris: redirect_uris,
        grant_types: [ "authorization_code", "refresh_token" ],
        response_types: [ "code" ],
        token_endpoint_auth_method: "none"
      }
    end

    def render_error(code, description)
      render json: { error: code, error_description: description }, status: :bad_request
    end

    def parse_body
      JSON.parse(request.body.read.presence || "{}")
    rescue JSON::ParserError
      {}
    end

    def allow_cross_origin
      response.set_header("Access-Control-Allow-Origin", "*")
    end
  end
end
