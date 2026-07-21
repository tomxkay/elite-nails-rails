class Review < ApplicationRecord
  validates :author_name, presence: true
  validates :rating, inclusion: { in: 1..5 }

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(approved: true) }

  # ⚠️ INTENTIONALLY EMPTY — do not add invented reviews here.
  #
  # This constant previously held six fabricated testimonials labelled
  # `source: "Google"`. They were removed on 2026-07-21 because they were not
  # real: generic names, uniform 5-star ratings, and two quotes describing
  # services the salon has never offered ("spa pedicure", Michael doing
  # "fine-line art" — he does acrylic sets). Attributing invented praise to
  # named strangers on a real business's site is fabrication, and it also
  # contradicted the true Google rating of 4.2.
  #
  # A testimonial may only be added here if it is a REAL review, copied
  # verbatim, with the reviewer's actual name, date and star rating. The owner
  # can export these from the Google Business Profile dashboard
  # (Reviews → Manage reviews). Nothing here may be paraphrased, composed,
  # "cleaned up", or generated to fill space — an empty section is honest, an
  # invented one is not.
  #
  # The testimonials section renders the aggregate rating and Google links with
  # no cards when this is empty, so shipping it blank is safe.
  DEFAULTS = [].freeze

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
