class Review < ApplicationRecord
  validates :author_name, presence: true
  validates :rating, inclusion: { in: 1..5 }

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(approved: true) }

  # In-code backup / canonical seed source (see Promotion for the pattern).
  DEFAULTS = [
    { author_name: "Sarah M.", rating: 5, relative_date: "2 weeks ago", source: "Google", position: 0,
      quote: "The staff here is incredibly friendly and talented! They always take their time to make sure every detail is perfect. My go-to spot for special occasions." },
    { author_name: "Jennifer L.", rating: 5, relative_date: "1 month ago", source: "Google", position: 1,
      quote: "Best nail salon in the area! Great prices and the quality is amazing. They're so gentle with cuticle work — I never feel rushed or uncomfortable." },
    { author_name: "Michelle R.", rating: 5, relative_date: "3 weeks ago", source: "Google", position: 2,
      quote: "I've been coming here for years and the consistency is unmatched. Clean salon, professional service, and my gel manicures last for weeks!" },
    { author_name: "Ana P.", rating: 5, relative_date: "2 months ago", source: "Google", position: 3,
      quote: "Michael did the most beautiful fine-line art for my wedding. Everyone asked where I got my nails done. Truly a local gem." },
    { author_name: "Karen T.", rating: 5, relative_date: "1 week ago", source: "Google", position: 4,
      quote: "The spa pedicure is pure relaxation. Warm, welcoming, and they remember your name every visit. Wouldn't go anywhere else." },
    { author_name: "Denise W.", rating: 5, relative_date: "5 weeks ago", source: "Google", position: 5,
      quote: "Spotlessly clean and the whole family is so kind. Fair prices and they never rush. Highly recommend to anyone in Cramerton." }
  ].freeze

  def self.defaults
    DEFAULTS.map { |attrs| new(attrs) }
  end

  # Visible DB records, else the in-code backup. Resilient to a missing table.
  def self.for_display
    records = table_exists? ? visible.ordered.to_a : []
    records.presence || defaults
  rescue ActiveRecord::ActiveRecordError
    defaults
  end
end
