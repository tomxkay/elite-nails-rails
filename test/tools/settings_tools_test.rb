require "test_helper"

# Exercises the MCP tools for the SiteSetting singleton and BusinessHour rows.
class SettingsToolsTest < ActiveSupport::TestCase
  test "get site settings falls back to in-code defaults when the table is empty" do
    SiteSetting.delete_all
    data = JSON.parse(GetSiteSettingsTool.new.call)
    assert_equal SiteSetting::DEFAULTS[:name], data["name"]
  end

  test "update site settings creates the singleton row and audits before/after" do
    SiteSetting.delete_all

    result = JSON.parse(UpdateSiteSettingsTool.new.call(phone_display: "(704) 555-0000"))
    assert result["ok"]
    assert_equal 1, SiteSetting.count
    assert_equal "(704) 555-0000", SiteSetting.current.phone_display

    log = AuditLog.where(action: "update", record_type: "SiteSetting").last
    assert_equal "(704) 555-0000", log.details["after"]["phone_display"]

    # Second update hits the same singleton row, not a new one.
    JSON.parse(UpdateSiteSettingsTool.new.call(price_range: "$$$"))
    assert_equal 1, SiteSetting.count
  end

  test "set business hours upserts a day and closed clears times" do
    BusinessHour.delete_all

    result = JSON.parse(SetBusinessHoursTool.new.call(wday: 1, opens: "09:00", closes: "18:00"))
    assert result["ok"]
    assert_equal "09:00", BusinessHour.find_by(wday: 1).opens

    result = JSON.parse(SetBusinessHoursTool.new.call(wday: 1, closed: true))
    hour = BusinessHour.find_by(wday: 1)
    assert hour.closed
    assert_nil hour.opens
    assert_equal 1, BusinessHour.where(wday: 1).count
    assert_equal 2, AuditLog.where(action: "set_hours").count
  end

  test "business hours reject a bad time format via schema validation" do
    assert_raises(FastMcp::Tool::InvalidArgumentsError) do
      SetBusinessHoursTool.new.call_with_schema_validation!(wday: 1, opens: "9am")
    end
  end

  test "get business hours returns days plus grouped display" do
    BusinessHour.delete_all
    data = JSON.parse(GetBusinessHoursTool.new.call)
    assert_equal 7, data["days"].size
    assert data["display"].any?
  end
end
