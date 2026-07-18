require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "record! stores the action, record reference, source, and details" do
    promo = Promotion.create!(title: "X")

    log = AuditLog.record!(
      action: "create", record: promo,
      summary: "made X", details: { after: { title: "X" } }
    )

    assert_equal "create", log.action
    assert_equal "Promotion", log.record_type
    assert_equal promo.id, log.record_id
    assert_equal "mcp", log.source
    assert_equal({ "after" => { "title" => "X" } }, log.details)
  end

  test "requires an action" do
    assert_not AuditLog.new(action: nil).valid?
  end
end
