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

  # Guard, not a style rule. DEFAULTS held six invented testimonials labelled as
  # Google reviews until 2026-07-21 — two of them praised services the salon
  # never offered. Seeding them again would republish fabricated praise
  # attributed to named people. Real reviews belong in the DB (added verbatim
  # from the Google Business Profile), never in this constant, because anything
  # placed here is auto-seeded into every environment as a stand-in for content
  # that doesn't exist yet.
  test "DEFAULTS stays empty so no fabricated testimonials ship" do
    assert_empty Review::DEFAULTS,
      "Review::DEFAULTS must stay empty — see the comment in app/models/review.rb. " \
      "Add real, verbatim reviews to the database instead of seeding invented ones."
  end

  test "renders no testimonial cards when there are no reviews" do
    assert_equal 0, Review.count
    assert_empty Review.for_display
  end
end
