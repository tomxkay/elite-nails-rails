# The Square OAuth credential for the native booking flow (one row per
# environment). Stored in the DB (encrypted) rather than env vars so the
# ~30-day access token can renew itself: SquareApi refreshes it lazily just
# before expiry on the next booking-related request — more reliable than a
# scheduled job on Fly machines that auto-stop when idle.
#
# Rows are written by SquareOauthController#callback (initial mint) and
# #refresh! afterwards. ENV["SQUARE_ACCESS_TOKEN"] remains a fallback when no
# row exists (e.g. fresh checkout before the one-time authorize).
class SquareCredential < ApplicationRecord
  encrypts :access_token, :refresh_token

  validates :environment, presence: true, uniqueness: true

  # Renew this far ahead of expiry so a token never goes stale mid-flow.
  REFRESH_AHEAD = 3.days

  def self.current
    find_by(environment: SquareApi.environment)
  rescue ActiveRecord::ActiveRecordError
    nil # table missing (pre-migration boot) — SquareApi falls back to ENV
  end

  # Upsert from a Square OAuth token response (authorization_code or refresh
  # grant — both return the same shape).
  def self.store_oauth!(payload, environment:)
    credential = find_or_initialize_by(environment: environment)
    credential.update!(
      access_token: payload["access_token"],
      # Refresh grants may omit the refresh token; keep the existing one then.
      refresh_token: payload["refresh_token"].presence || credential.refresh_token,
      expires_at: payload["expires_at"].presence && Time.iso8601(payload["expires_at"]),
      merchant_id: payload["merchant_id"]
    )
    credential
  end

  def needs_refresh?
    refresh_token.present? && expires_at.present? && expires_at < REFRESH_AHEAD.from_now
  end

  # Exchange the refresh token for a fresh access token and persist it.
  # Square refresh tokens are long-lived and not rotated on use, so concurrent
  # refreshes are harmless (last write wins with an equivalent token).
  def refresh!
    payload = SquareApi.oauth_token(grant_type: "refresh_token", refresh_token: refresh_token)
    self.class.store_oauth!(payload, environment: environment)
  end
end
