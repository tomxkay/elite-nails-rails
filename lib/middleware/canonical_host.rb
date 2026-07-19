# frozen_string_literal: true

# Redirects browser traffic on alternate hosts (www.<canonical>, *.fly.dev)
# to the canonical domain, so the public site has one identity for SEO.
# Enabled only when CANONICAL_HOST is set (production).
#
# Machine endpoints are exempt on purpose: the owner's claude.ai MCP connector
# and its OAuth/discovery flow are registered against the fly.dev host, and
# API clients don't reliably follow redirects on POST. Those keep answering on
# whatever host they're called on.
class CanonicalHost
  EXEMPT_PREFIXES = [ "/mcp", "/oauth", "/.well-known", "/owner", "/up" ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    canonical = ENV["CANONICAL_HOST"].presence
    return @app.call(env) unless canonical

    request = Rack::Request.new(env)
    return @app.call(env) if request.host == canonical
    return @app.call(env) if EXEMPT_PREFIXES.any? { |p| request.path == p || request.path.start_with?("#{p}/") }

    location = "https://#{canonical}#{request.fullpath}"
    # 308 preserves the request method, though in practice these are GETs.
    [ 308, { "Location" => location, "Content-Type" => "text/plain" }, [ "Redirecting to #{location}" ] ]
  end
end
