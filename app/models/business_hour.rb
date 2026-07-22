class BusinessHour < ApplicationRecord
  # wday follows Ruby's Date#wday: 0 = Sunday .. 6 = Saturday.
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  # Display order: Monday first, Sunday last.
  DISPLAY_ORDER = [1, 2, 3, 4, 5, 6, 0].freeze

  validates :wday, presence: true, inclusion: { in: 0..6 }

  # In-code backup / canonical seed source.
  DEFAULTS = [
    { wday: 1, opens: "10:00", closes: "18:00", closed: false },
    { wday: 2, opens: "10:00", closes: "18:00", closed: false },
    { wday: 3, opens: "10:00", closes: "18:00", closed: false },
    { wday: 4, opens: "10:00", closes: "18:00", closed: false },
    { wday: 5, opens: "10:00", closes: "18:00", closed: false },
    { wday: 6, opens: "09:00", closes: "17:00", closed: false },
    { wday: 0, opens: nil, closes: nil, closed: true }
  ].freeze

  def self.defaults
    DEFAULTS.map { |attrs| new(attrs) }
  end

  # Rows ordered Monday → Sunday, from the DB or the in-code backup.
  def self.for_display
    rows = table_exists? ? all.to_a : []
    rows = defaults if rows.empty?
    rows.sort_by { |h| DISPLAY_ORDER.index(h.wday) }
  rescue ActiveRecord::ActiveRecordError
    defaults.sort_by { |h| DISPLAY_ORDER.index(h.wday) }
  end

  def day_name
    DAY_NAMES[wday]
  end

  # "10:00 AM – 6:00 PM" or "Closed".
  def display_hours
    return "Closed" if closed? || opens.blank? || closes.blank?
    "#{format_time(opens)} – #{format_time(closes)}"
  end

  # Consecutive days sharing identical hours, grouped into display rows:
  #   [["Monday – Friday", "10:00 AM – 6:00 PM"], ["Saturday", "9:00 AM – 5:00 PM"], ["Sunday", "Closed"]]
  def self.grouped_for_display
    for_display.slice_when { |a, b| a.display_hours != b.display_hours }.map do |group|
      label = group.size == 1 ? group.first.day_name : "#{group.first.day_name} – #{group.last.day_name}"
      [label, group.first.display_hours]
    end
  end

  # schema.org openingHoursSpecification entries (open days only), grouping days
  # that share opens/closes.
  def self.opening_hours_specification
    open_days = for_display.reject { |h| h.closed? || h.opens.blank? || h.closes.blank? }
    open_days.group_by { |h| [h.opens, h.closes] }.map do |(opens, closes), days|
      {
        "@type" => "OpeningHoursSpecification",
        "dayOfWeek" => days.map(&:day_name),
        "opens" => opens,
        "closes" => closes
      }
    end
  end

  private

  def format_time(hhmm)
    Time.strptime(hhmm, "%H:%M").strftime("%-l:%M %p")
  rescue ArgumentError
    hhmm
  end
end
