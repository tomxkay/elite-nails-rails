class Promotion < ApplicationRecord
  validates :title, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> {
    today = Date.current
    where(active: true)
      .where("starts_on IS NULL OR starts_on <= ?", today)
      .where("ends_on IS NULL OR ends_on >= ?", today)
  }

  # In-code backup / canonical seed data. Kept in code so the site still renders
  # (and can be re-seeded) even if the DB is empty or unavailable. This is the
  # source db/seeds.rb loads from.
  DEFAULTS = [
    {
      title: "Your First Visit",
      deal: "15% Off",
      badge: "New Guests",
      featured: true,
      description: "New to Elite Nails? Enjoy 15% off any service on your very first appointment — our way of saying welcome to the family.",
      fine_print: "First-time guests only. One per person.",
      position: 0
    },
    {
      title: "Refer a Friend",
      deal: "$10 Off",
      featured: false,
      description: "Send a friend our way and you both get $10 off your next service.",
      fine_print: "Applied after their first visit.",
      position: 1
    },
    {
      title: "Birthday Treat",
      deal: "Free",
      featured: false,
      description: "Celebrate with a complimentary nail-art add-on during your birthday month.",
      fine_print: "Valid with any manicure.",
      position: 2
    },
    {
      title: "Tues–Thurs Gel Special",
      deal: "Midweek",
      featured: false,
      description: "Book a gel manicure Tuesday through Thursday for a relaxed, quieter visit.",
      fine_print: "Subject to availability.",
      position: 3
    }
  ].freeze

  # Unsaved instances built from the in-code backup.
  def self.defaults
    DEFAULTS.map { |attrs| new(attrs) }
  end

  # What the site renders: visible DB records if any exist, otherwise the in-code
  # backup. Resilient to a missing table (e.g. before the first migration).
  def self.for_display
    records = table_exists? ? visible.ordered.to_a : []
    records.presence || defaults
  rescue ActiveRecord::ActiveRecordError
    defaults
  end
end
