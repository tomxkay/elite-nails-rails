require "test_helper"

class SiteSettingTest < ActiveSupport::TestCase
  test "current falls back to in-code defaults when none persisted" do
    assert_equal 0, SiteSetting.count

    current = SiteSetting.current
    assert_not current.persisted?
    assert_equal SiteSetting::DEFAULTS[:name], current.name
    assert_equal SiteSetting::DEFAULTS[:aggregate_rating], current.aggregate_rating.to_f
  end

  test "current returns the persisted row when present" do
    SiteSetting.create!(SiteSetting::DEFAULTS.merge(name: "Custom Salon"))

    assert SiteSetting.current.persisted?
    assert_equal "Custom Salon", SiteSetting.current.name
  end

  test "requires a name" do
    assert_not SiteSetting.new(name: nil).valid?
  end
end
