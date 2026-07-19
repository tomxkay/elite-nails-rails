class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # First-party page-view tracking (Ahoy). Runs after the response so it can
  # never delay or break a page render. See docs/analytics-plan.md.
  after_action :track_pageview

  private

  def track_pageview
    return unless trackable_pageview?

    ahoy.track("page_viewed", path: request.path)
  rescue StandardError => e
    # Analytics must never take a page down.
    Rails.logger.warn("[Analytics] page view tracking failed: #{e.class}: #{e.message}")
  end

  # Only count real, human, successful page loads — not JSON/XML endpoints,
  # non-GET requests, redirects/errors, Turbo prefetches, or Do-Not-Track users.
  def trackable_pageview?
    request.get? &&
      request.format.html? &&
      response.successful? &&
      !turbo_prefetch? &&
      !do_not_track?
  end

  def turbo_prefetch?
    request.headers["Sec-Purpose"].to_s.include?("prefetch")
  end

  def do_not_track?
    request.headers["DNT"] == "1" || request.headers["Sec-GPC"] == "1"
  end
end
