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
end
