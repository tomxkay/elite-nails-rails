# frozen_string_literal: true

class SetPricingItemActiveTool < ApplicationTool
  description "Show or hide a pricing menu item without deleting it. Set active: false " \
              "to take it off the menu (reversible), or active: true to bring it back."

  annotations(
    title: "Show/hide pricing item",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Pricing item id (from ListPricingItemsTool)")
    required(:active).filled(:bool).description("true = visible, false = hidden")
  end

  def call(id:, active:)
    item = PricingItem.find_by(id: id)
    return json(ok: false, error: "No pricing item with id #{id}") unless item

    item.update!(active: active)
    audit!(action: "set_active", record: item,
           summary: "#{active ? 'Showed' : 'Hid'} pricing item '#{item.name}'",
           details: { active: active })
    json(ok: true, pricing_item: serialize_pricing_item(item))
  end
end
