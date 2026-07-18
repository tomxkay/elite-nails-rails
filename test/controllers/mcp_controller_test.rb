require "test_helper"

# Protocol tests for the Streamable HTTP MCP endpoint (POST /mcp). Requests go
# through the full stack, so they authenticate with a static token via the
# McpDualAuth middleware.
class McpControllerTest < ActionDispatch::IntegrationTest
  TOKEN = "mcp-test-token".freeze

  setup do
    @original_token = ENV["MCP_AUTH_TOKEN"]
    ENV["MCP_AUTH_TOKEN"] = TOKEN
  end

  teardown do
    @original_token.nil? ? ENV.delete("MCP_AUTH_TOKEN") : ENV["MCP_AUTH_TOKEN"] = @original_token
  end

  def rpc(method, params: nil, id: 1)
    body = { jsonrpc: "2.0", method: method, id: id }
    body[:params] = params if params
    post "/mcp", params: body.to_json,
                 headers: { "CONTENT_TYPE" => "application/json",
                            "Authorization" => "Bearer #{TOKEN}" }
    response.body.present? ? JSON.parse(response.body) : nil
  end

  test "initialize returns protocol version and tools capability" do
    result = rpc("initialize")["result"]
    assert_equal McpController::PROTOCOL_VERSION, result["protocolVersion"]
    assert result["capabilities"].key?("tools")
    assert_equal "elite-nails", result.dig("serverInfo", "name")
  end

  test "notifications get 202 with no body" do
    rpc("notifications/initialized")
    assert_response :accepted
    assert response.body.blank?
  end

  test "ping returns an empty result" do
    assert_equal({}, rpc("ping")["result"])
  end

  test "tools/list returns all registered tools with schemas" do
    tools = rpc("tools/list").dig("result", "tools")
    assert_equal McpController::TOOL_CLASS_NAMES.sort, tools.map { |t| t["name"] }.sort
    list_tool = tools.find { |t| t["name"] == "ListPromotionsTool" }
    assert list_tool["description"].present?
    assert_equal "object", list_tool.dig("inputSchema", "type")
    assert_equal true, list_tool.dig("annotations", "readOnlyHint")
  end

  test "tools/call runs a tool and returns text content" do
    Promotion.delete_all
    Promotion.create!(title: "Test Promo", deal: "10% off", active: true, position: 1)

    body = rpc("tools/call", params: { name: "ListPromotionsTool", arguments: { only_active: true } })
    content = body.dig("result", "content", 0)
    assert_equal "text", content["type"]
    assert_includes content["text"], "Test Promo"
    assert_equal false, body.dig("result", "isError")
  end

  test "tools/call with invalid arguments returns isError content, not a crash" do
    body = rpc("tools/call", params: { name: "CreatePromotionTool", arguments: { title: "" } })
    assert_equal true, body.dig("result", "isError")
    assert_includes body.dig("result", "content", 0, "text"), "invalid arguments"
  end

  test "tools/call with unknown tool returns a JSON-RPC error" do
    body = rpc("tools/call", params: { name: "NopeTool" })
    assert_equal(-32_602, body.dig("error", "code"))
  end

  test "unknown method returns a JSON-RPC error" do
    assert_equal(-32_601, rpc("bogus/method").dig("error", "code"))
  end

  test "invalid JSON returns a parse error" do
    post "/mcp", params: "{nope",
                 headers: { "CONTENT_TYPE" => "application/json",
                            "Authorization" => "Bearer #{TOKEN}" }
    assert_equal(-32_700, JSON.parse(response.body).dig("error", "code"))
  end

  test "GET and DELETE are rejected with 405" do
    get "/mcp", headers: { "Authorization" => "Bearer #{TOKEN}" }
    assert_response :method_not_allowed
    delete "/mcp", headers: { "Authorization" => "Bearer #{TOKEN}" }
    assert_response :method_not_allowed
  end
end
