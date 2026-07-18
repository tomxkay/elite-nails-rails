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
require 'fast_mcp'

# Bearer-token auth: enabled whenever MCP_AUTH_TOKEN is set (required in
# production; leave unset in dev for easy local testing). The owner pastes this
# token into their Claude connector's Authorization header. See
# docs/cms-ai-roadmap.md for how the owner connects.
mcp_token = ENV["MCP_AUTH_TOKEN"].presence

FastMcp.mount_in_rails(
  Rails.application,
  name: Rails.application.class.module_parent_name.underscore.dasherize,
  version: '1.0.0',
  path_prefix: '/mcp',
  messages_route: 'messages',
  sse_route: 'sse',
  authenticate: mcp_token.present?,
  auth_token: mcp_token
  # allowed_origins defaults to Rails.application.config.hosts. When connecting a
  # real Claude client from claude.ai, ensure the production host + Anthropic
  # origins are permitted (verify at deploy time — see roadmap).
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
