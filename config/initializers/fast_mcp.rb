# frozen_string_literal: true

# FastMcp - Model Context Protocol for Rails
# This initializer sets up the MCP middleware in your Rails application.
#
# In Rails applications, you can use:
# - ActionTool::Base as an alias for FastMcp::Tool
# - ActionResource::Base as an alias for FastMcp::Resource
#
# All your tools should inherit from ApplicationTool which already uses ActionTool::Base,
# and all your resources should inherit from ApplicationResource which uses ActionResource::Base.

# Mount the MCP middleware in your Rails application
# You can customize the options below to fit your needs.
require "fast_mcp"

# Auth is owned by the McpDualAuth middleware (inserted below, ahead of the
# fast-mcp transport): it accepts EITHER the static MCP_AUTH_TOKEN (Claude Code)
# OR a Doorkeeper OAuth access token (claude.ai), and answers everything else
# with 401 + a WWW-Authenticate challenge that triggers OAuth discovery.
# fast-mcp's built-in static-token auth stays disabled (authenticate: false).
require Rails.root.join("lib/middleware/mcp_dual_auth")
Rails.application.config.middleware.use McpDualAuth

# Client-IP + Origin (DNS-rebinding) protections. Remote clients (Claude via
# ngrok in dev, or Anthropic in production) are never "localhost", so localhost_only
# must be false whenever we accept remote connections.
#
# - Non-production: fully permissive origin so a tunnelled dev client connects.
# - Production: restrict origins to the app host(s). Set MCP_ALLOWED_ORIGINS as a
#   comma-separated list to add more (e.g. a custom domain). Note the request
#   Origin is often absent for server-to-server MCP calls, in which case fast-mcp
#   falls back to the request host — so the app host must be listed.
mcp_localhost_only = false
mcp_allowed_origins =
  if Rails.env.production?
    [ "elite-nails-rails.fly.dev", *ENV["MCP_ALLOWED_ORIGINS"].to_s.split(",").map(&:strip) ]
  else
    [ /.*/ ]
  end

FastMcp.mount_in_rails(
  Rails.application,
  name: Rails.application.class.module_parent_name.underscore.dasherize,
  version: "1.0.0",
  path_prefix: "/mcp",
  messages_route: "messages",
  sse_route: "sse",
  authenticate: false,
  localhost_only: mcp_localhost_only,
  allowed_origins: mcp_allowed_origins
) do |server|
  Rails.application.config.after_initialize do
    # Registered explicitly (rather than ApplicationTool.descendants) so tools load
    # reliably in development, where classes are not eager-loaded.
    server.register_tools(
      ListPromotionsTool,
      CreatePromotionTool,
      UpdatePromotionTool,
      SetPromotionActiveTool
    )
  end
end
