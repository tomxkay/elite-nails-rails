require "test_helper"

# Exercises the MCP tools for services, pricing, team, and reviews at the Ruby
# level (list/create/update/hide + audit), mirroring promotion_tools_test.rb.
class ContentToolsTest < ActiveSupport::TestCase
  # --- Services -------------------------------------------------------------

  test "service tools: list filters, create appends + audits, hide is reversible" do
    Service.create!(title: "Visible", active: true)
    Service.create!(title: "Hidden", active: false)
    data = JSON.parse(ListServicesTool.new.call(only_active: true))
    assert_equal [ "Visible" ], data.map { |h| h["title"] }

    result = JSON.parse(CreateServiceTool.new.call(title: "Waxing", pricing_category: "Add-Ons"))
    assert result["ok"]
    assert_equal 1, AuditLog.where(action: "create", record_type: "Service").count

    id = result["service"]["id"]
    result = JSON.parse(UpdateServiceTool.new.call(id: id, description: "Smooth."))
    assert result["ok"]
    assert_equal "Smooth.", Service.find(id).description

    JSON.parse(SetServiceActiveTool.new.call(id: id, active: false))
    assert_not Service.find(id).active
    assert Service.exists?(id)
  end

  test "service create validation error is returned, not raised" do
    result = JSON.parse(CreateServiceTool.new.call(title: ""))
    assert_not result["ok"]
    assert result["error"].present?
  end

  # --- Pricing --------------------------------------------------------------

  test "pricing tools: create in category, update price with audit trail, hide" do
    result = JSON.parse(CreatePricingItemTool.new.call(category: "Hands", name: "Gel Manicure", price: "$35"))
    assert result["ok"]

    id = result["pricing_item"]["id"]
    result = JSON.parse(UpdatePricingItemTool.new.call(id: id, price: "$40"))
    assert result["ok"]
    assert_equal "$40", PricingItem.find(id).price
    log = AuditLog.where(action: "update", record_type: "PricingItem").last
    assert_equal "$35", log.details["before"]["price"]
    assert_equal "$40", log.details["after"]["price"]

    JSON.parse(SetPricingItemActiveTool.new.call(id: id, active: false))
    assert_not PricingItem.find(id).active
  end

  test "pricing create rejects an unknown category via schema validation" do
    assert_raises(FastMcp::Tool::InvalidArgumentsError) do
      CreatePricingItemTool.new.call_with_schema_validation!(category: "Nope", name: "X")
    end
  end

  # --- Team -----------------------------------------------------------------

  test "team tools: create with specialties, update, hide" do
    result = JSON.parse(CreateTeamMemberTool.new.call(name: "Lien Ka", specialties: [ "Pedicures", "Nail Art" ]))
    assert result["ok"]
    assert_equal [ "Pedicures", "Nail Art" ], result["team_member"]["specialties"]

    id = result["team_member"]["id"]
    result = JSON.parse(UpdateTeamMemberTool.new.call(id: id, role: "Senior Technician"))
    assert result["ok"]
    assert_equal "Senior Technician", TeamMember.find(id).role

    JSON.parse(SetTeamMemberActiveTool.new.call(id: id, active: false))
    assert_not TeamMember.find(id).active
    assert TeamMember.exists?(id)
  end

  # --- Reviews --------------------------------------------------------------

  test "review tools: create, feature via update, hide via approved" do
    result = JSON.parse(CreateReviewTool.new.call(author_name: "Sarah M.", rating: 5, quote: "Lovely!"))
    assert result["ok"]

    id = result["review"]["id"]
    result = JSON.parse(UpdateReviewTool.new.call(id: id, featured: true))
    assert result["ok"]
    assert Review.find(id).featured

    JSON.parse(SetReviewApprovedTool.new.call(id: id, approved: false))
    assert_not Review.find(id).approved
    assert Review.exists?(id)
    assert_equal 1, AuditLog.where(action: "set_approved", record_type: "Review").count
  end

  test "review rating outside 1-5 is rejected by schema validation" do
    assert_raises(FastMcp::Tool::InvalidArgumentsError) do
      CreateReviewTool.new.call_with_schema_validation!(author_name: "X", rating: 6)
    end
  end

  test "update tools return an error for a missing id" do
    [ UpdateServiceTool.new.call(id: 0, title: "x"),
      UpdatePricingItemTool.new.call(id: 0, price: "$1"),
      UpdateTeamMemberTool.new.call(id: 0, name: "x"),
      UpdateReviewTool.new.call(id: 0, quote: "x") ].each do |raw|
      assert_not JSON.parse(raw)["ok"]
    end
  end
end
