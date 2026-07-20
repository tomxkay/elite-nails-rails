class TeamMember < ApplicationRecord
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(active: true) }

  # In-code backup / canonical seed source (see Promotion for the pattern).
  # image is nil for now (renders the placeholder portrait until real photos land).
  #
  # Bios and specialty tags name only services that actually exist on the menu
  # (docs/service-menu-reconciliation.md) — the previous copy advertised a
  # "Spa Pedicure" the salon never offered.
  #
  # `bookable` gates online booking. Only Michael takes /book appointments for
  # now; the rest of the team books by phone or walk-in and will opt in as they
  # get comfortable with it.
  DEFAULTS = [
    {
      name: "Michael",
      role: "Owner & Lead Technician",
      quote: "Every set should feel like it was made just for you.",
      bio: "Specializes in sculpted acrylic full sets and fills. Known for a gentle touch and a calming demeanor.",
      specialties: ["Acrylic Full Set", "Acrylic Fill", "Gel Manicure"],
      bookable: true,
      position: 0
    },
    {
      name: "Nhan",
      role: "Senior Technician",
      quote: "Color is where I get to play — let's find yours.",
      bio: "Loves creative color work and deluxe pedicures. Guests rave about her relaxing massages.",
      specialties: ["Deluxe Pedicure", "Gel Polish", "Dip Powder"],
      position: 1
    },
    {
      name: "Lien",
      role: "Nail Technician",
      quote: "Clean shapes, strong nails, and a warm welcome every time.",
      bio: "Precise shaping and durable acrylic work with a friendly, welcoming vibe.",
      specialties: ["Acrylic Full Set", "Gel Manicure", "Natural Looks"],
      position: 2
    }
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
