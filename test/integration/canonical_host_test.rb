require "test_helper"

class CanonicalHostTest < ActionDispatch::IntegrationTest
  def with_canonical(host)
    original = ENV["CANONICAL_HOST"]
    host.nil? ? ENV.delete("CANONICAL_HOST") : ENV["CANONICAL_HOST"] = host
    yield
  ensure
    original.nil? ? ENV.delete("CANONICAL_HOST") : ENV["CANONICAL_HOST"] = original
  end

  test "alternate hosts redirect to the canonical domain preserving the path" do
    with_canonical("elitenailscramerton.com") do
      get "https://www.elitenailscramerton.com/book"
      assert_response 308
      assert_equal "https://elitenailscramerton.com/book", response.headers["Location"]

      get "https://elite-nails-rails.fly.dev/?utm=x"
      assert_response 308
      assert_equal "https://elitenailscramerton.com/?utm=x", response.headers["Location"]
    end
  end

  test "canonical host and machine endpoints are not redirected" do
    with_canonical("elitenailscramerton.com") do
      get "https://elitenailscramerton.com/up"
      assert_response :success

      # MCP on the fly.dev host must keep working for the claude.ai connector.
      post "https://elite-nails-rails.fly.dev/mcp",
           params: { jsonrpc: "2.0", method: "ping", id: 1 }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
      assert_response :unauthorized # dual-auth challenge, not a redirect

      get "https://elite-nails-rails.fly.dev/.well-known/oauth-protected-resource"
      assert_response :success
    end
  end

  test "disabled when CANONICAL_HOST is unset" do
    with_canonical(nil) do
      get "https://www.elitenailscramerton.com/up"
      assert_response :success
    end
  end
end
