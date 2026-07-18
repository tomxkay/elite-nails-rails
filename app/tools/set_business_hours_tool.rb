# frozen_string_literal: true

class SetBusinessHoursTool < ApplicationTool
  description "Set the hours for ONE day of the week (call once per day to change " \
              "several). Changes the contact section and SEO opening-hours data " \
              "immediately. Use closed: true for a day off."

  annotations(
    title: "Set business hours",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:wday).filled(:integer, gteq?: 0, lteq?: 6)
      .description("Day of week: 0 = Sunday, 1 = Monday … 6 = Saturday")
    optional(:opens).filled(:string, format?: /\A\d{2}:\d{2}\z/)
      .description("Opening time, 24h HH:MM, e.g. '10:00'")
    optional(:closes).filled(:string, format?: /\A\d{2}:\d{2}\z/)
      .description("Closing time, 24h HH:MM, e.g. '19:00'")
    optional(:closed).filled(:bool).description("true = closed all day (opens/closes ignored)")
  end

  def call(wday:, **attrs)
    hour = BusinessHour.find_or_initialize_by(wday: wday)
    before = hour.persisted? ? serialize_business_hour(hour) : nil
    attrs = { opens: nil, closes: nil }.merge(attrs) if attrs[:closed]
    hour.update!(attrs)
    audit!(action: "set_hours", record: hour,
           summary: "Set #{hour.day_name} hours to #{hour.display_hours}",
           details: { before: before, after: serialize_business_hour(hour) })
    json(ok: true, business_hour: serialize_business_hour(hour))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
