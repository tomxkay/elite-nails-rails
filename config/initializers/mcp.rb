# frozen_string_literal: true

# MCP is served by McpController — Streamable HTTP JSON-RPC at POST /mcp
# (initialize, ping, tools/list, tools/call). fast-mcp's Rack/SSE transport is
# NOT mounted: claude.ai's connector requires Streamable HTTP. The fast-mcp gem
# is still used for the tool layer (ApplicationTool < ActionTool::Base with
# dry-schema argument validation); tools are registered in
# McpController::TOOL_CLASS_NAMES.
#
# McpDualAuth guards /mcp ahead of the router: requests need EITHER the static
# MCP_AUTH_TOKEN bearer token (Claude Code) OR a Doorkeeper OAuth access token
# (claude.ai). Anything else gets 401 + a WWW-Authenticate challenge pointing
# at the RFC 9728 metadata, which triggers a client's OAuth discovery flow.
# The gem's dashed name ("fast-mcp") means Bundler does not auto-require it.
require "fast_mcp"

require Rails.root.join("lib/middleware/mcp_dual_auth")
Rails.application.config.middleware.use McpDualAuth

# Canonical-domain redirect (www/fly.dev → CANONICAL_HOST) for the public
# site; exempts MCP/OAuth/discovery endpoints. See the class for rationale.
require Rails.root.join("lib/middleware/canonical_host")
Rails.application.config.middleware.insert_before McpDualAuth, CanonicalHost
