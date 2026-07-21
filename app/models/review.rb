class Review < ApplicationRecord
  validates :author_name, presence: true
  validates :rating, inclusion: { in: 1..5 }

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> { where(approved: true) }

  # ⚠️ REAL REVIEWS ONLY. Every entry below is a genuine customer review supplied
  # by the owner from the salon's Google Business Profile (2026-07-21), quoted
  # verbatim. Surnames are reduced to an initial for privacy — that is the only
  # permitted alteration. Nothing here may be paraphrased, composed, "cleaned
  # up", trimmed to fit the card, or generated to fill space.
  #
  # History: this constant previously held six FABRICATED testimonials labelled
  # `source: "Google"` — generic names, uniform 5★, and two quotes praising
  # services the salon has never offered ("spa pedicure"; Michael doing
  # "fine-line art" when he does acrylic sets). They shipped to production and
  # went unnoticed for months, which is precisely the risk: placeholder reviews
  # are indistinguishable from real ones once deployed. See
  # docs/reviews-and-ratings.md.
  #
  # `relative_date` is intentionally omitted: the posting dates weren't captured
  # with the review text, and the card hides the date when it's blank. Inventing
  # plausible dates ("2 weeks ago") is what the fabricated set did. Add real
  # dates if they're ever recorded; leave blank otherwise.
  #
  # `rating: 5` is inferred from the text of each review, not read off the
  # profile — every quote here is unambiguous praise. Correct any that don't
  # match the actual star rating on Google.
  DEFAULTS = [
    { author_name: "Dorethea H.", rating: 5, source: "Google", position: 0,
      quote: "I have been a client for twenty years. This family is amazing! They are friendly, professional, and genuinely care for everyone. The salon is always immaculate, and they make everyone feel welcome and valued." },
    { author_name: "Allison S.", rating: 5, source: "Google", position: 1,
      quote: "I've been going here since I was 15 years old, and I'm almost 25 now. They have always been kind, welcoming, and accommodating. Michael always goes above and beyond, and they have some of the best prices in town for the beautiful work they do!" },
    { author_name: "Valerie C.", rating: 5, source: "Google", position: 2,
      quote: "It is without question the best salon I've been to. The technicians were efficient, pleasant, and professional. They were visibly keeping everything very clean and sanitary. I will definitely be back!" },
    { author_name: "Melissa K.", rating: 5, source: "Google", position: 3,
      quote: "This was my first time, and it was a great experience. My manicure lasted more than two weeks without chipping. I only needed it redone because my nails had grown. I will definitely be back!" },
    # Held back initially because it names "Thai", who wasn't on the team list.
    # Owner confirmed 2026-07-21 that Thai Tran is a technician here, so the
    # review is safe to publish — the name now matches a real team card.
    { author_name: "Leslie D.", rating: 5, source: "Google", position: 4,
      quote: "Elite Nails has been doing my nails for 11 years. Thai shapes them so beautifully that I am asked at least once a week if my nails are real." },
    { author_name: "Heidi B.", rating: 5, source: "Google", position: 5,
      quote: "I had an amazing set and then the best fill-in and reshaping. Clean, on time, and professional." }
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
