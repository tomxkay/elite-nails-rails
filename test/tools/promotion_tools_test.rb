require "test_helper"

# Exercises the MCP promotion tools at the Ruby level (create/update/hide + audit).
class PromotionToolsTest < ActiveSupport::TestCase
  test "list returns only active promotions when requested" do
    Promotion.create!(title: "Visible", active: true)
    Promotion.create!(title: "Hidden", active: false)

    data = JSON.parse(ListPromotionsTool.new.call(only_active: true))
    assert_equal ["Visible"], data.map { |h| h["title"] }
  end

  test "create appends position and writes an audit log" do
    result = JSON.parse(CreatePromotionTool.new.call(title: "New Promo", deal: "10% Off"))

    assert result["ok"]
    assert_equal 0, result["promotion"]["position"]
    assert_equal 1, AuditLog.where(action: "create", record_type: "Promotion").count
  end

  test "create validation error is returned, not raised" do
    result = JSON.parse(CreatePromotionTool.new.call(title: ""))
    assert_not result["ok"]
    assert result["error"].present?
  end

  test "update changes fields and audits before/after" do
    promo = Promotion.create!(title: "P", deal: "old")

    result = JSON.parse(UpdatePromotionTool.new.call(id: promo.id, deal: "Free"))

    assert result["ok"]
    assert_equal "Free", promo.reload.deal
    log = AuditLog.where(action: "update").last
    assert_equal "old", log.details["before"]["deal"]
    assert_equal "Free", log.details["after"]["deal"]
  end

  test "update returns an error for a missing id" do
    result = JSON.parse(UpdatePromotionTool.new.call(id: 0, title: "x"))
    assert_not result["ok"]
  end

  test "set_active hides a promotion without deleting it" do
    promo = Promotion.create!(title: "P", active: true)

    JSON.parse(SetPromotionActiveTool.new.call(id: promo.id, active: false))

    assert_not promo.reload.active
    assert Promotion.exists?(promo.id)
    assert_equal 1, AuditLog.where(action: "set_active").count
  end
end
