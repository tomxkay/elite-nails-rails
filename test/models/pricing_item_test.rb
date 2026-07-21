require "test_helper"

class PricingItemTest < ActiveSupport::TestCase
  test "requires category and name" do
    assert_not PricingItem.new(category: nil, name: "X").valid?
    assert_not PricingItem.new(category: "Hands", name: nil).valid?
    assert PricingItem.new(category: "Hands", name: "Gel Manicure").valid?
  end

  test "for_display falls back to in-code defaults when empty" do
    assert_equal 0, PricingItem.count

    fallback = PricingItem.for_display
    assert_equal PricingItem::DEFAULTS.map { |d| d[:name] }, fallback.map(&:name)
    assert fallback.none?(&:persisted?)
  end

  test "grouped_for_display groups by category in CATEGORY_ORDER" do
    PricingItem.create!(category: "Add-Ons", name: "Nail Art", position: 2)
    PricingItem.create!(category: "Hands", name: "Gel", position: 0)
    PricingItem.create!(category: "Feet", name: "Spa Pedi", position: 1)

    assert_equal ["Hands", "Feet", "Add-Ons"], PricingItem.grouped_for_display.map(&:first)
  end

  test "grouped_for_display excludes inactive items" do
    PricingItem.create!(category: "Hands", name: "Visible", position: 0)
    PricingItem.create!(category: "Hands", name: "Hidden", position: 1, active: false)

    hands = PricingItem.grouped_for_display.to_h["Hands"]
    assert_equal ["Visible"], hands.map(&:name)
  end

  # Online booking is limited to what the single opted-in technician performs.
  # Michael does Manicures and Acrylic, Dip & Extensions only, so a bookable item
  # in any other category would offer a slot nobody can work. Widen this list
  # when another technician opts in — and update the Square catalog to match, or
  # /book will keep offering the old set regardless of this flag.
  BOOKABLE_CATEGORIES = [ "Manicures", "Acrylic, Dip & Extensions" ].freeze

  test "only categories the bookable technician performs are bookable" do
    offenders = PricingItem::DEFAULTS
      .select { |attrs| attrs[:bookable] }
      .map { |attrs| attrs[:category] }
      .uniq - BOOKABLE_CATEGORIES

    assert_empty offenders,
      "These categories have bookable services but no technician takes them online: " \
      "#{offenders.join(', ')}. See docs/booking-adoption-notes.md."
  end

  test "every bookable item has the duration Square needs" do
    PricingItem::DEFAULTS.select { |attrs| attrs[:bookable] }.each do |attrs|
      assert attrs[:duration_minutes].to_i.positive?,
        "#{attrs[:name]} is bookable but has no duration — Square can't schedule it."
    end
  end
end
