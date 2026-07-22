# Receives client-reported KPI events from the browser (analytics.js) and records
# them via Ahoy. Public + unauthenticated, so it is deliberately locked down:
# only allow-listed event names are accepted, properties are sanitized to a small
# flat bag, and the endpoint is rate-limited. See docs/analytics-plan.md.
class EventsController < ApplicationController
  include RateLimiter

  # The only events the browser may report. Booking outcomes and page views are
  # tracked server-side (trustworthy) and are intentionally NOT here — the client
  # must not be able to spoof a completed booking.
  ALLOWED_EVENTS = %w[
    service_selected
    slot_selected
    phone_click
    book_cta_clicked
    square_fallback_clicked
  ].freeze

  MAX_PROPERTIES = 20
  MAX_STRING_LENGTH = 200

  before_action :throttle_events, only: :create

  # POST /events  { name: "...", properties: { ... } }
  def create
    return head :no_content if skip_analytics?
    return head :unprocessable_entity unless ALLOWED_EVENTS.include?(params[:name].to_s)

    ahoy.track(params[:name].to_s, event_properties)
    head :no_content
  rescue StandardError => e
    # Analytics failures are never the client's problem.
    Rails.logger.warn("[Analytics] event tracking failed: #{e.class}: #{e.message}")
    head :no_content
  end

  private

  def throttle_events
    throttle(scope: "events", limit: 120, period: 1.minute)
  end

  # Accept only a small, flat bag of primitive properties: bounded count, no
  # nested structures, strings truncated. Keeps arbitrary/huge payloads out of
  # the events table.
  def event_properties
    raw = params[:properties]
    return {} unless raw.respond_to?(:each_pair)

    raw.to_unsafe_h.first(MAX_PROPERTIES).to_h.transform_values do |value|
      case value
      when Numeric, true, false, nil then value
      else value.to_s.first(MAX_STRING_LENGTH)
      end
    end
  end
end
