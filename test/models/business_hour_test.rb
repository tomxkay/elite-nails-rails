require "test_helper"

class BusinessHourTest < ActiveSupport::TestCase
  test "display_hours formats 24h times and handles closed" do
    assert_equal "10:00 AM – 7:00 PM", BusinessHour.new(wday: 1, opens: "10:00", closes: "19:00").display_hours
    assert_equal "9:00 AM – 6:00 PM", BusinessHour.new(wday: 6, opens: "09:00", closes: "18:00").display_hours
    assert_equal "Closed", BusinessHour.new(wday: 0, closed: true).display_hours
  end

  test "grouped_for_display groups consecutive days with equal hours (defaults)" do
    assert_equal 0, BusinessHour.count

    grouped = BusinessHour.grouped_for_display
    assert_equal ["Monday – Friday", "10:00 AM – 6:00 PM"], grouped[0]
    assert_equal ["Saturday", "9:00 AM – 5:00 PM"], grouped[1]
    assert_equal ["Sunday", "Closed"], grouped[2]
  end

  test "opening_hours_specification excludes closed days and groups by hours" do
    spec = BusinessHour.opening_hours_specification
    weekday = spec.find { |s| s["opens"] == "10:00" }
    assert_equal %w[Monday Tuesday Wednesday Thursday Friday], weekday["dayOfWeek"]
    assert_not spec.any? { |s| s["dayOfWeek"].include?("Sunday") }
  end
end
