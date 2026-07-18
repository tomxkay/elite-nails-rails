class TeamMember < ApplicationRecord
  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(active: true) }

  # In-code backup / canonical seed source (see Promotion for the pattern).
  # image is nil for now (renders the placeholder portrait until real photos land).
  DEFAULTS = [
    {
      name: "Michael K",
      role: "Owner & Lead Nail Artist",
      quote: "Every set should feel like it was made just for you.",
      bio: "Specializes in gel, dip, and fine-line nail art. Known for a gentle touch and calming demeanor.",
      specialties: ["Gel Art", "Dip Powder", "Fine Line"],
      position: 0
    },
    {
      name: "Nhan Ka",
      role: "Senior Technician",
      quote: "Color is where I get to play — let's find yours.",
      bio: "Loves creative color palettes and spa pedicures. Guests rave about her relaxing massages.",
      specialties: ["Spa Pedicure", "Color Pairing", "Massage"],
      position: 1
    },
    {
      name: "Lien Ka",
      role: "Nail Technician",
      quote: "Clean shapes, strong nails, and a warm welcome every time.",
      bio: "Precise shaping and durable acrylics with a friendly, welcoming vibe.",
      specialties: ["Acrylics", "Nail Shaping", "Natural Looks"],
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
