# frozen_string_literal: true

# Cache-backed, fixed-window per-client request throttling.
#
# Deliberately **fails open**: if the client can't be identified, or the cache
# backend is unavailable/unsupported, the request is allowed through. A throttle
# outage must never take booking offline — the throttle is a spam backstop, not a
# gate on legitimate customers.
#
# Usage (from a before_action):
#
#   before_action :throttle_create, only: :create
#
#   def throttle_create
#     throttle(scope: "book:create", limit: 10, period: 1.hour)
#   end
#
# When the cap is exceeded, `throttle` renders a 429 JSON body and returns true;
# because it renders, Rails halts the before_action chain automatically.
module RateLimiter
  extend ActiveSupport::Concern

  private

  # Returns true if the request was throttled (a 429 was rendered and the chain
  # should stop), false if it may continue.
  def throttle(scope:, limit:, period:, message: nil)
    client = throttle_client_id
    return false if client.blank? # unidentifiable client → fail open

    count = throttle_increment(throttle_key(scope, client), period)
    return false if count.nil?      # cache unavailable/unsupported → fail open
    return false if count <= limit  # within the cap

    render_throttled(message, period)
    true
  end

  def throttle_key(scope, client)
    "throttle:#{scope}:#{client}"
  end

  def throttle_client_id
    request.remote_ip.presence
  end

  # Atomic increment with a TTL. Portable across SolidCache (prod) and
  # MemoryStore (dev) — both initialize a missing key to the amount and set the
  # expiry. Any failure (NotImplementedError from a null/unsupported store, or a
  # backend error such as a DB outage) resolves to nil so the caller fails open.
  def throttle_increment(key, period)
    Rails.cache.increment(key, 1, expires_in: period)
  rescue NotImplementedError, StandardError => e
    Rails.logger.warn("[RateLimiter] cache unavailable, allowing request: #{e.class}: #{e.message}")
    nil
  end

  def render_throttled(message, period)
    response.set_header("Retry-After", period.to_i.to_s)
    render json: {
      ok: false,
      error: message || "You're doing that a little too fast. Please wait a moment and try again, or call us to book."
    }, status: :too_many_requests
  end
end
