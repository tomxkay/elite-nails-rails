class PricingItem < ApplicationRecord
  validates :category, :name, presence: true

  # Display order of the pricing categories (keys are the stored `category`).
  CATEGORY_ORDER = %w[Hands Feet Add-Ons].freeze

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(active: true) }

  # In-code backup / canonical seed source (see Promotion for the pattern).
  DEFAULTS = [
    { category: "Hands", name: "Classic Manicure", price: "$20", position: 0 },
    { category: "Hands", name: "Gel Manicure", price: "$35", position: 1 },
    { category: "Hands", name: "Dip Powder", price: "$40", position: 2 },
    { category: "Hands", name: "French Add-On", price: "+$5", position: 3 },
    { category: "Feet", name: "Signature Pedicure", price: "$35", position: 4 },
    { category: "Feet", name: "Spa Pedicure", price: "$45", position: 5 },
    { category: "Feet", name: "Gel Pedicure", price: "$55", position: 6 },
    { category: "Feet", name: "Callus Care Upgrade", price: "+$8", position: 7 },
    { category: "Add-Ons", name: "Nail Art (per nail)", price: "$5+", position: 8 },
    { category: "Add-Ons", name: "Acrylic Full Set", price: "$40+", position: 9 },
    { category: "Add-Ons", name: "Acrylic Fill", price: "$30+", position: 10 },
    { category: "Add-Ons", name: "Waxing (brows/lip/chin)", price: "$10+", position: 11 }
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

  # Items grouped by category, in CATEGORY_ORDER (extra categories appended).
  def self.grouped_for_display
    grouped = for_display.group_by(&:category)
    ordered_keys = CATEGORY_ORDER & grouped.keys
    ordered_keys += (grouped.keys - CATEGORY_ORDER)
    ordered_keys.map { |cat| [cat, grouped[cat]] }
  end
end
