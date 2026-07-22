# Owner-facing analytics opt-out. Visiting /analytics/opt-out sets a persistent
# first-party cookie that every tracking path checks (ApplicationController#
# skip_analytics?), so the salon's own browsers don't pollute the stats now that
# the site is live. Per browser + device; forward-only. See docs/analytics-plan.md.
class AnalyticsController < ApplicationController
  # Not linked from anywhere and records nothing sensitive; still, keep it out of
  # search results.
  def opt_out
    # cookies.permanent → ~20-year expiry, so it survives browser restarts.
    # httponly: only the server reads it (the tracking gates), never JS.
    cookies.permanent[ApplicationController::ANALYTICS_OPT_OUT_COOKIE] = { value: "1", httponly: true }
    @opted_out = true
    render :status, layout: false
  end

  def opt_in
    cookies.delete(ApplicationController::ANALYTICS_OPT_OUT_COOKIE)
    @opted_out = false
    render :status, layout: false
  end
end
