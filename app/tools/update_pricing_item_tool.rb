# frozen_string_literal: true

class UpdatePricingItemTool < ApplicationTool
  description "Update a pricing menu item by id (e.g. change a price). Only provided " \
              "fields change. Changes appear on the website immediately and are audit-logged."

  annotations(
    title: "Update pricing item",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Pricing item id (from ListPricingItemsTool)")
    optional(:category).filled(:string, included_in?: PricingItem::CATEGORY_ORDER)
      .description("One of #{PricingItem::CATEGORY_ORDER.join(', ')}")
    optional(:name).filled(:string)
    optional(:price).filled(:string).description("Display price, e.g. '$35', '$40+', '+$5'")
    optional(:active).filled(:bool)
    optional(:bookable).filled(:bool)
      .description("Whether it can be booked online at /book. A service must also exist in the " \
                   "Square catalog for booking to actually work.")
    optional(:position).filled(:integer)
  end

  def call(id:, **attrs)
    item = PricingItem.find_by(id: id)
    return json(ok: false, error: "No pricing item with id #{id}") unless item

    before = serialize_pricing_item(item)
    item.update!(attrs)
    audit!(action: "update", record: item,
           summary: "Updated pricing item '#{item.name}' (#{attrs.keys.join(', ')})",
           details: { before: before, after: serialize_pricing_item(item) })
    json(ok: true, pricing_item: serialize_pricing_item(item))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
