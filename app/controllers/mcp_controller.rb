# frozen_string_literal: true

# Minimal JSON-RPC endpoint implementing the subset of MCP that Claude's
# Streamable HTTP transport needs: initialize, ping, tools/list, tools/call.
# fast-mcp 1.6's Rack transport only speaks the deprecated SSE protocol, which
# claude.ai's connector can't use — it POSTs JSON-RPC straight to /mcp — so we
# serve the protocol ourselves and keep fast-mcp only for the tool classes
# (ActionTool::Base + dry-schema argument validation).
#
# Auth (static MCP_AUTH_TOKEN or Doorkeeper OAuth token) is enforced by the
# McpDualAuth middleware before the router; unauthenticated requests never
# reach this controller.
class McpController < ActionController::Base
  skip_forgery_protection # bearer-token API endpoint, not a browser session

  PROTOCOL_VERSION = "2025-03-26"

  # Explicit tool registry, constantized per-request so dev reloading works.
  TOOL_CLASS_NAMES = %w[
    ListPromotionsTool
    CreatePromotionTool
    UpdatePromotionTool
    SetPromotionActiveTool
  ].freeze

  def handle
    req = JSON.parse(request.body.read)
    # JSON-RPC notifications (e.g. notifications/initialized) get no response.
    return head :accepted if req["method"].to_s.start_with?("notifications/")

    render json: route_jsonrpc(req)
  rescue JSON::ParserError
    render json: error_response(nil, -32_700, "invalid JSON")
  end

  # Streamable HTTP also defines GET (server-initiated SSE stream) and DELETE
  # (session termination); we support neither, which the spec answers with 405.
  def reject
    head :method_not_allowed
  end

  private

  def route_jsonrpc(req)
    id = req["id"]
    case req["method"]
    when "initialize"
      success_response(id,
                       protocolVersion: PROTOCOL_VERSION,
                       capabilities: { tools: { listChanged: false } },
                       serverInfo: { name: "elite-nails", version: "1.0.0" })
    when "ping"
      success_response(id, {})
    when "tools/list"
      success_response(id, tools: tool_classes.map { |tool| tool_descriptor(tool) })
    when "tools/call"
      handle_tool_call(req)
    else
      error_response(id, -32_601, "unknown method #{req['method']}")
    end
  end

  def handle_tool_call(req)
    id = req["id"]
    params = req["params"] || {}
    tool = tool_classes.find { |t| t.tool_name == params["name"] }
    return error_response(id, -32_602, "unknown tool #{params['name']}") unless tool

    args = (params["arguments"] || {}).deep_symbolize_keys
    result, = tool.new(headers: {}).call_with_schema_validation!(**args)
    success_response(id, content: [ { type: "text", text: result.to_s } ], isError: false)
  rescue FastMcp::Tool::InvalidArgumentsError => e
    tool_error_response(id, "invalid arguments: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("MCP tool #{params['name']} failed: #{e.class}: #{e.message}")
    tool_error_response(id, "tool failed: #{e.message}")
  end

  def tool_classes
    TOOL_CLASS_NAMES.map(&:constantize)
  end

  def tool_descriptor(tool)
    descriptor = {
      name: tool.tool_name,
      description: tool.description || "",
      inputSchema: tool.input_schema_to_json || { type: "object", properties: {}, required: [] }
    }
    annotations = tool.annotations
    unless annotations.empty?
      descriptor[:annotations] = annotations.transform_keys { |key| key.to_s.camelize(:lower).to_sym }
    end
    descriptor
  end

  def success_response(id, result)
    { jsonrpc: "2.0", id: id, result: result }
  end

  def error_response(id, code, message)
    { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
  end

  # MCP convention: tool-level failures are a successful JSON-RPC response with
  # isError: true, so the model sees the message and can retry/rephrase.
  def tool_error_response(id, message)
    success_response(id, content: [ { type: "text", text: message } ], isError: true)
  end
end
