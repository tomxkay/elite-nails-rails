require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "requires an author name and a 1-5 rating" do
    assert_not Review.new(author_name: nil, rating: 5).valid?
    assert_not Review.new(author_name: "Sam", rating: 6).valid?
    assert Review.new(author_name: "Sam", rating: 5).valid?
  end

  test "visible excludes unapproved reviews, ordered by position" do
    Review.create!(author_name: "Second", position: 1)
    Review.create!(author_name: "First", position: 0)
    Review.create!(author_name: "Pending", approved: false)

    assert_equal ["First", "Second"], Review.visible.ordered.map(&:author_name)
  end

  test "for_display falls back to in-code defaults when empty" do
    assert_equal 0, Review.count

    fallback = Review.for_display
    assert_equal Review::DEFAULTS.map { |d| d[:author_name] }, fallback.map(&:author_name)
    assert fallback.none?(&:persisted?)
  end

  # The six invented testimonials that shipped to production until 2026-07-21.
  # Named here so they can never quietly return. See docs/reviews-and-ratings.md.
  FABRICATED_AUTHORS = [
    "Sarah M.", "Jennifer L.", "Michelle R.", "Ana P.", "Karen T.", "Denise W."
  ].freeze

  test "DEFAULTS never re-admits the fabricated testimonials" do
    returning = Review::DEFAULTS.map { |d| d[:author_name] } & FABRICATED_AUTHORS

    assert_empty returning,
      "These author names belong to testimonials that were invented, not collected: " \
      "#{returning.join(', ')}. Only real reviews quoted verbatim may be seeded — " \
      "see app/models/review.rb and docs/reviews-and-ratings.md."
  end

  # Guards the shape of a real review rather than its wording: a fabricated entry
  # is easiest to spot when attribution is missing or vague.
  test "every seeded review carries full attribution" do
    assert Review::DEFAULTS.any?, "expected the real Google reviews to be seeded"

    Review::DEFAULTS.each do |attrs|
      assert attrs[:quote].to_s.strip.present?, "review is missing its quote: #{attrs.inspect}"
      assert attrs[:author_name].to_s.strip.present?, "review is missing an author"
      assert attrs[:source].to_s.strip.present?, "review must record where it came from"
      assert_includes 1..5, attrs[:rating], "review needs a 1-5 star rating"
    end
  end

  # A published review that praises a technician by name sends guests asking for
  # that person. If they don't work there, the salon has to explain it at the
  # counter. Two supplied reviews name "Ty" and "Mrs. Vann", who are not on the
  # team; they stay unpublished until the owner confirms who they are.
  # "Thai" was in the same position until 2026-07-21, when the owner confirmed
  # him — so this is about verification, not a permanent blocklist.
  test "seeded reviews only name technicians who work here" do
    unconfirmed = [ /\bTy\b/, /Mrs\.? ?Vann/i ]
    team = TeamMember::DEFAULTS.map { |m| m[:name] }

    Review::DEFAULTS.each do |attrs|
      unconfirmed.each do |pattern|
        assert_no_match pattern, attrs[:quote],
          "#{attrs[:author_name]}'s review names someone who isn't on the team " \
          "(#{team.join(', ')}). Confirm with the owner before publishing it."
      end
    end
  end

  # The fabricated set described a "spa pedicure" and Michael doing "fine-line
  # art" — neither has ever been on the menu. A quote naming a service the salon
  # doesn't offer is the strongest signal a review was written rather than received.
  test "seeded reviews do not mention services the salon has never offered" do
    invented_services = [ /spa pedicure/i, /fine[- ]line/i ]

    Review::DEFAULTS.each do |attrs|
      invented_services.each do |pattern|
        assert_no_match pattern, attrs[:quote],
          "#{attrs[:author_name]}'s review mentions a service the salon doesn't offer — " \
          "verify this is a real review and not placeholder copy."
      end
    end
  end
end
