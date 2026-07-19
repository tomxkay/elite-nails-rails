class Service < ApplicationRecord
  validates :title, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(active: true) }

  # In-code backup / canonical seed source (see Promotion for the pattern).
  # `image` is an asset filename resolved via responsive_service_image_sources.
  DEFAULTS = [
    {
      title: "Gel & Dip Powder",
      description: "Long-lasting, chip-resistant color with gel polish or dip powder systems. Up to 3 weeks of gorgeous nails.",
      featured: true,
      image: "manicure-service-768.webp",
      pricing_category: "hands",
      position: 0
    },
    {
      title: "Manicures",
      description: "Classic and spa manicures featuring premium products, cuticle care, nail shaping, and your choice of polish.",
      image: "manicure-service-768.webp",
      pricing_category: "hands",
      position: 1
    },
    {
      title: "Pedicures",
      description: "Relax with our signature pedicures including foot soak, exfoliation, massage, and polish.",
      image: "pedicure-service-768.webp",
      pricing_category: "feet",
      position: 2
    },
    {
      title: "Acrylic & Extensions",
      description: "Custom acrylic nail enhancements, tips, and sculpted extensions for length and strength.",
      image: "manicure-service-768.webp",
      pricing_category: "add-ons",
      position: 3
    },
    {
      title: "Nail Art & Design",
      description: "Express yourself with custom nail art, hand-painted designs, gems, foils, and trending styles.",
      image: "nail-art-service-768.webp",
      pricing_category: "add-ons",
      position: 4
    },
    {
      title: "Waxing Services",
      description: "Professional waxing services for brows, lip, chin, and more with gentle techniques.",
      image: "pedicure-service-768.webp",
      pricing_category: "add-ons",
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
