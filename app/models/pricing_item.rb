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
    { category: "Manicures", name: "Manicure", price: "$30", position: 0, bookable: true, duration_minutes: 30,
      description: "Nail shaping, cuticle care, a relaxing hand massage, and your choice of classic polish." },
    { category: "Manicures", name: "Gel Manicure", price: "$40", position: 1, bookable: true, duration_minutes: 45,
      description: "A full manicure finished with gel polish — cured to a high shine that resists chips for up to three weeks." },
    { category: "Manicures", name: "French Gel Manicure", price: "$40", position: 2, bookable: true, duration_minutes: 60,
      description: "Our gel manicure with the timeless white-tip French finish, hand-painted and cured to last." },

    { category: "Pedicures", name: "Pedicure", price: "$30", position: 3, bookable: true, duration_minutes: 45,
      description: "Nail shaping, cuticle care, a light callus buff, sugar scrub, massage, hot towel, and polish." },
    { category: "Pedicures", name: "Deluxe Pedicure", price: "$40", position: 4, bookable: true, duration_minutes: 60,
      description: "Everything in the classic pedicure, plus callus treatment, paraffin wax, and an extended massage." },
    { category: "Pedicures", name: "Gel Pedicure", price: "$50", position: 5, bookable: true, duration_minutes: 60,
      description: "A full pedicure finished with long-wearing gel polish that keeps its shine for weeks." },
    { category: "Pedicures", name: "Manicure + Pedicure", price: "$50", position: 6, bookable: true, duration_minutes: 75,
      description: "Our classic manicure and pedicure together — and $10 less than booking them separately." },

    { category: "Polish & Color", name: "Gel Polish", price: "$25", position: 7, bookable: true, duration_minutes: 30,
      description: "Gel color applied to prepped nails — polish only, without the full manicure." },
    { category: "Polish & Color", name: "French Gel Polish", price: "$30", position: 8, bookable: true, duration_minutes: 40,
      description: "Gel color with a hand-painted French tip — polish only, without the full manicure." },
    { category: "Polish & Color", name: "Polish Change", price: "$12", position: 9, duration_minutes: 15,
      description: "A quick change of classic polish on clean, prepped nails." },
    { category: "Polish & Color", name: "French Polish Change", price: "$16", position: 10, duration_minutes: 25,
      description: "A quick polish change with a hand-painted French tip." },
    { category: "Polish & Color", name: "Nail Art (per nail)", price: "$5+", position: 11, duration_minutes: 10,
      description: "Hand-painted designs, from a simple accent to detailed art. Priced per nail by design." },

    { category: "Acrylic, Dip & Extensions", name: "Dip Powder", price: "$40", position: 12, bookable: true, duration_minutes: 60,
      description: "Color powder sealed layer by layer for a durable, lightweight finish that wears two to three weeks — no UV lamp needed." },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Full Set", price: "$40", position: 13, bookable: true, duration_minutes: 75,
      description: "Sculpted acrylic extensions shaped to your preferred length, finished with classic polish." },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Full Set (Gel)", price: "$55", position: 14, bookable: true, duration_minutes: 90,
      description: "The same sculpted set, finished with long-wearing gel polish." },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Fill", price: "$25", position: 15, bookable: true, duration_minutes: 45,
      description: "Rebalances your existing set as the natural nail grows out, refreshed with classic polish." },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Fill (Gel)", price: "$40", position: 16, bookable: true, duration_minutes: 60,
      description: "The same fill, refreshed with gel polish." },
    { category: "Acrylic, Dip & Extensions", name: "Acrylic Removal", price: "$15", position: 17, duration_minutes: 30,
      description: "Gentle soak-off that lifts acrylic away without damaging the natural nail underneath." },
    { category: "Acrylic, Dip & Extensions", name: "Nail Repair", price: "$5", position: 18, duration_minutes: 15,
      description: "Repair for a single cracked or broken nail." },

    { category: "Nail Care", name: "Nail Trim", price: "$10+", position: 19, duration_minutes: 15,
      description: "Trimming and shaping for fingers or toes. Toenail work is priced higher — it's more involved." },

    { category: "Waxing", name: "Eyebrow", price: "$10", position: 20, duration_minutes: 15,
      description: "Shaping and cleanup to define your natural brow line." },
    { category: "Waxing", name: "Lip", price: "$7", position: 21, duration_minutes: 10,
      description: "Quick, precise upper-lip waxing." },
    { category: "Waxing", name: "Brow + Lip", price: "$15", position: 22, duration_minutes: 20,
      description: "Both together — $2 less than booking separately." },
    { category: "Waxing", name: "Chin", price: "$30+", position: 23, duration_minutes: 30,
      description: "Priced by coverage and time; a denser area than brow or lip." }
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
