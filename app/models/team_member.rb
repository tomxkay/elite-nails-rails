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
  # get comfortable with it (see docs/booking-adoption-notes.md). Adding a
  # bookable tech also requires assigning them to service variations in Square,
  # or availability search returns nothing for them.
  #
  # Only first names are displayed — a 2026-07-20 decision. Surnames are kept in
  # the comments below purely so staff can be told apart internally:
  #   Michael Ka · Thai Tran · Trang Tran · Mui Vu · Nhan Ka · Lien Ka
  #
  # Several technicians are related by marriage (it's a family salon). Those
  # relationships are deliberately NOT published — they're personal details about
  # people who haven't been asked. Add them only if the owner confirms each
  # person is happy to have it on a public page.
  DEFAULTS = [
    {
      name: "Michael",
      role: "Senior Nail Technician",
      quote: "Every set should feel like it was made just for you.",
      bio: "Specializes in sculpted acrylic full sets and fills. Known for a gentle touch and a calming demeanor.",
      specialties: ["Acrylic Full Set", "Acrylic Fill", "Gel Manicure"],
      bookable: true,
      position: 0
    },
    {
      name: "Thai",
      role: "Senior Nail Technician",
      quote: "Twenty years in, and I still want every shape to be perfect.",
      bio: "More than twenty years behind the table, with the same strengths as Michael — sculpted acrylic sets, fills, and gel work. Regulars come back for his shaping.",
      specialties: ["Acrylic Full Set", "Acrylic Fill", "Gel Manicure"],
      position: 1
    },
    {
      name: "Trang",
      role: "Senior Technician & Nail Artist",
      quote: "Bring me a picture — I'd love to paint it.",
      bio: "Twenty-plus years of experience across the whole menu, with a special love for hand-painted nail art. Happy to take on a detailed design or keep it simple.",
      specialties: ["Nail Art", "Gel Manicure", "Acrylic Full Set"],
      position: 2
    },
    {
      name: "Mui",
      role: "Pedicure & Waxing Specialist",
      quote: "Sit back — this part is supposed to feel good.",
      bio: "Over ten years of experience and our go-to for pedicures and waxing. Known for a thorough, unhurried deluxe pedicure that guests plan their week around.",
      specialties: ["Deluxe Pedicure", "Gel Pedicure", "Waxing"],
      position: 3
    },
    {
      name: "Nhan",
      role: "Senior Nail Technician",
      quote: "Color is where I get to play — let's find yours.",
      bio: "Loves creative color work and deluxe pedicures. Guests rave about her relaxing massages.",
      specialties: ["Deluxe Pedicure", "Gel Polish", "Dip Powder"],
      position: 4
    },
    {
      name: "Lien",
      role: "Senior Nail Technician",
      quote: "Clean shapes, strong nails, and a warm welcome every time.",
      bio: "Precise shaping and durable acrylic work with a friendly, welcoming vibe.",
      specialties: ["Acrylic Full Set", "Gel Manicure", "Natural Looks"],
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
