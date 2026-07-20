class PricingItem < ApplicationRecord
  validates :category, :name, presence: true

  # Display order of the pricing categories (keys are the stored `category`).
  CATEGORY_ORDER = [ "Manicures", "Pedicures", "Polish & Color", "Acrylic, Dip & Extensions", "Nail Care", "Waxing" ].freeze

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(active: true) }

  # In-code backup / canonical seed source (see Promotion for the pattern).
  #
  # Sourced from the salon's in-house letter board + owner confirmation
  # (2026-07-20) — see docs/service-menu-reconciliation.md for the full
  # reconciliation, durations, and the reasoning behind each name. `bookable`
  # marks the longer services offered through /book; short/add-on work stays
  # walk-in.
  #
  # NOTE: French Gel Manicure is knowingly $5 under its own logic (French Gel
  # Polish is +$5 over Gel Polish). Owner's deliberate choice — do not "fix".
  DEFAULTS = [
    { category: "Manicures", name: "Manicure", price: "$30", position: 0, bookable: true },
    { category: "Manicures", name: "Gel Manicure", price: "$40", position: 1, bookable: true },
    { category: "Manicures", name: "French Gel Manicure", price: "$40", position: 2, bookable: true },

    { category: "Pedicures", name: "Pedicure", price: "$30", position: 3, bookable: true },
    { category: "Pedicures", name: "Deluxe Pedicure", price: "$40", position: 4, bookable: true },
    { category: "Pedicures", name: "Gel Pedicure", price: "$50", position: 5, bookable: true },
    { category: "Pedicures", name: "Manicure + Pedicure", price: "$50", position: 6, bookable: true },

    { category: "Polish & Color", name: "Gel Polish", price: "$25", position: 7, bookable: true },
    { category: "Polish & Color", name: "French Gel Polish", price: "$30", position: 8, bookable: true },
    { category: "Polish & Color", name: "Polish Change", price: "$12", position: 9 },
    { category: "Polish & Color", name: "French Polish Change", price: "$16", position: 10 },
    { category: "Polish & Color", name: "Nail Art (per nail)", price: "$5+", position: 11 },

    { category: "Acrylic, Dip & Extensions", name: "Dip Powder", price: "$40", position: 12, bookable: true },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Full Set", price: "$40", position: 13, bookable: true },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Full Set (Gel)", price: "$55", position: 14, bookable: true },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Fill", price: "$25", position: 15, bookable: true },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Fill (Gel)", price: "$40", position: 16, bookable: true },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Removal", price: "$15", position: 17 },
    { category: "Acrylic, Dip & Extensions", name: "Nail Repair", price: "$5", position: 18 },

    { category: "Nail Care", name: "Nail Trim", price: "$10+", position: 19 },

    { category: "Waxing", name: "Eyebrow", price: "$10", position: 20 },
    { category: "Waxing", name: "Lip", price: "$7", position: 21 },
    { category: "Waxing", name: "Brow + Lip", price: "$15", position: 22 },
    { category: "Waxing", name: "Chin", price: "$30+", position: 23 }
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
