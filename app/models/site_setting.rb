class SiteSetting < ApplicationRecord
  validates :name, presence: true

  # In-code backup / canonical seed source. Single source of truth for the salon's
  # NAP, geo, price range, founding year, and the reviews aggregate.
  # NOTE: geo coordinates are approximate — verify exact lat/lng before launch.
  DEFAULTS = {
    name: "Elite Nails",
    phone: "+17048249032",
    phone_display: "(704) 824-9032",
    street: "202 Market St F",
    city: "Cramerton",
    region: "NC",
    postal_code: "28032",
    country: "US",
    latitude: 35.2387,
    longitude: -81.0737,
    price_range: "$$",
    established: 2003,
    aggregate_rating: 4.9,
    review_count: 120
  }.freeze

  # The singleton settings row — the persisted record, or an unsaved in-code
  # default when none exists / the table is unavailable.
  def self.current
    (table_exists? ? first : nil) || new(DEFAULTS)
  rescue ActiveRecord::ActiveRecordError
    new(DEFAULTS)
  end
end
