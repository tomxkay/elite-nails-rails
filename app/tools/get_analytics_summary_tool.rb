# frozen_string_literal: true

class GetAnalyticsSummaryTool < ApplicationTool
  description "Read first-party website analytics for a recent time window: " \
              "visits, unique visitors, top traffic sources, device mix, the " \
              "booking-funnel step counts and drop-off, and the visit→booking " \
              "conversion rate. Use this to report KPIs or assemble a dashboard. " \
              "Data is anonymized and read-only."

  annotations(
    title: "Get analytics summary",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:days).filled(:integer, gteq?: 1, lteq?: 365)
      .description("Look-back window in days, ending now (default 30, max 365)")
  end

  def call(days: 30)
    json(Analytics::Summary.new(since: days.days.ago).overview)
  end
end
