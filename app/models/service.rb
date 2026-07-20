class Service < ApplicationRecord
  validates :title, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(active: true) }

  # In-code backup / canonical seed source (see Promotion for the pattern).
  # `image` is an asset filename resolved via responsive_service_image_sources.
  #
  # One card per PricingItem category, and `pricing_category` must stay equal to
  # that category downcased — the pricing_highlight Stimulus controller matches
  # on it to flash the right price panel. See PricingItem::CATEGORY_ORDER and
  # docs/service-menu-reconciliation.md.
  DEFAULTS = [
    {
      title: "Manicures",
      description: "Nail shaping, cuticle care, and a relaxing hand massage — finished with classic or long-wearing gel polish.",
      featured: true,
      image: "manicure-service-768.webp",
      pricing_category: "manicures",
      position: 0
    },
    {
      title: "Pedicures",
      description: "A warm soak, scrub, and massage. Go deluxe for callus treatment, paraffin wax, and extra time to unwind.",
      image: "pedicure-service-768.webp",
      pricing_category: "pedicures",
      position: 1
    },
    {
      title: "Acrylic, Dip & Extensions",
      description: "Sculpted acrylic sets, fills, and dip powder — built for length and strength, finished your way.",
      image: "acrylic-service-768.webp",
      pricing_category: "acrylic, dip & extensions",
      position: 2
    },
    {
      title: "Polish & Color",
      description: "Gel color, French tips, quick polish changes, and hand-painted nail art priced by design.",
      image: "nail-art-service-768.webp",
      pricing_category: "polish & color",
      position: 3
    },
    {
      title: "Nail Care",
      description: "Trims and shaping for fingers and toes, plus quick repairs when a nail needs rescuing.",
      image: "nail-care-service-768.webp",
      pricing_category: "nail care",
      position: 4
    },
    {
      title: "Waxing",
      description: "Gentle brow, lip, and chin waxing — book the brow and lip together and save.",
      image: "waxing-service-768.webp",
      pricing_category: "waxing",
      position: 5
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
