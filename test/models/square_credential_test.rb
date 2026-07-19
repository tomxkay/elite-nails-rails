require "test_helper"
require "minitest/mock"

class SquareCredentialTest < ActiveSupport::TestCase
  OAUTH_PAYLOAD = {
    "access_token" => "buyer-token-1",
    "refresh_token" => "refresh-1",
    "expires_at" => "2026-08-18T00:00:00Z",
    "merchant_id" => "MERCH1"
  }.freeze

  test "store_oauth! creates then updates a single row per environment" do
    credential = SquareCredential.store_oauth!(OAUTH_PAYLOAD, environment: "sandbox")
    assert_equal "buyer-token-1", credential.access_token
    assert_equal Time.iso8601("2026-08-18T00:00:00Z"), credential.expires_at

    # A refresh grant without a refresh_token keeps the existing one.
    SquareCredential.store_oauth!(
      { "access_token" => "buyer-token-2", "expires_at" => "2026-09-17T00:00:00Z" },
      environment: "sandbox"
    )
    assert_equal 1, SquareCredential.count
    credential.reload
    assert_equal "buyer-token-2", credential.access_token
    assert_equal "refresh-1", credential.refresh_token
  end

  test "needs_refresh? only near expiry and only with a refresh token" do
    fresh = SquareCredential.new(refresh_token: "r", expires_at: 20.days.from_now)
    near = SquareCredential.new(refresh_token: "r", expires_at: 1.day.from_now)
    no_refresh = SquareCredential.new(refresh_token: nil, expires_at: 1.day.from_now)

    assert_not fresh.needs_refresh?
    assert near.needs_refresh?
    assert_not no_refresh.needs_refresh?
  end

  test "refresh! exchanges the refresh token and persists the new access token" do
    credential = SquareCredential.store_oauth!(OAUTH_PAYLOAD, environment: "sandbox")
    renewed = { "access_token" => "buyer-token-9", "expires_at" => "2026-10-01T00:00:00Z" }

    SquareApi.stub(:oauth_token, renewed) do
      credential.refresh!
    end
    assert_equal "buyer-token-9", credential.reload.access_token
    assert_equal "refresh-1", credential.refresh_token
  end

  test "tokens are encrypted at rest" do
    SquareCredential.store_oauth!(OAUTH_PAYLOAD, environment: "sandbox")
    raw = SquareCredential.connection.select_value(
      "SELECT access_token FROM square_credentials LIMIT 1"
    )
    assert_not_equal "buyer-token-1", raw
  end
end
