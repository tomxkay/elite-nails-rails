require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "requires a title" do
    assert_not Service.new(title: nil).valid?
    assert Service.new(title: "Gel Manicure").valid?
  end

  test "visible excludes inactive services, ordered by position" do
    Service.create!(title: "Second", position: 1)
    Service.create!(title: "First", position: 0)
    Service.create!(title: "Hidden", active: false)

    assert_equal ["First", "Second"], Service.visible.ordered.map(&:title)
  end

  test "for_display returns persisted DB records when present" do
    Service.create!(title: "Real Service", position: 0)

    result = Service.for_display
    assert_includes result.map(&:title), "Real Service"
    assert result.all?(&:persisted?)
  end

  test "for_display falls back to in-code defaults when empty" do
    assert_equal 0, Service.count

    fallback = Service.for_display
    assert_equal Service::DEFAULTS.map { |d| d[:title] }, fallback.map(&:title)
    assert fallback.none?(&:persisted?)
  end
end
