require "test_helper"

class PromotionTest < ActiveSupport::TestCase
  test "requires a title" do
    assert_not Promotion.new(title: nil).valid?
    assert Promotion.new(title: "Spring Special").valid?
  end

  test "visible excludes inactive and out-of-window promotions" do
    Promotion.create!(title: "Active")
    Promotion.create!(title: "Inactive", active: false)
    Promotion.create!(title: "Future", starts_on: Date.current + 1)
    Promotion.create!(title: "Expired", ends_on: Date.current - 1)

    assert_equal [ "Active" ], Promotion.visible.ordered.map(&:title)
  end

  test "ordered sorts by position then id" do
    Promotion.create!(title: "Second", position: 1)
    Promotion.create!(title: "First", position: 0)

    assert_equal [ "First", "Second" ], Promotion.ordered.map(&:title)
  end

  test "for_display returns persisted DB records when present" do
    Promotion.create!(title: "Real Deal", position: 0)

    result = Promotion.for_display
    assert_includes result.map(&:title), "Real Deal"
    assert result.all?(&:persisted?)
  end

  test "for_display falls back to in-code defaults when table is empty" do
    assert_equal 0, Promotion.count

    fallback = Promotion.for_display
    assert_equal Promotion::DEFAULTS.map { |d| d[:title] }, fallback.map(&:title)
    assert fallback.none?(&:persisted?), "fallback promotions should be unsaved in-code defaults"
  end

  test "primary_for_display returns the first featured visible promotion" do
    Promotion.create!(title: "Regular", featured: false, position: 0)
    Promotion.create!(title: "Featured", featured: true, position: 1)

    assert_equal "Featured", Promotion.primary_for_display.title
  end

  test "primary_for_display falls back to the first visible promotion" do
    Promotion.create!(title: "First", featured: false, position: 0)
    Promotion.create!(title: "Second", featured: false, position: 1)

    assert_equal "First", Promotion.primary_for_display.title
  end
end
