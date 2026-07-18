# frozen_string_literal: true

class GetBusinessHoursTool < ApplicationTool
  description "Read the salon's weekly business hours, both per-day and as the " \
              "grouped display used on the site (e.g. 'Monday – Friday: 10 AM – 7 PM')."

  annotations(
    title: "Get business hours",
    read_only_hint: true,
    open_world_hint: false
  )

  def call
    json(
      days: BusinessHour.for_display.map { |h| serialize_business_hour(h) },
      display: BusinessHour.grouped_for_display.map { |label, hours| "#{label}: #{hours}" }
    )
  end
end
