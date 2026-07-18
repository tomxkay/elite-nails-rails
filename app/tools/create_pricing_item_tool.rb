# frozen_string_literal: true

class CreatePricingItemTool < ApplicationTool
  description "Add an item to the pricing menu. It appears on the website immediately. " \
              "Price is free-form text so formats like '$40+', '+$5' are preserved."

  annotations(
    title: "Add pricing item",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:category).filled(:string, included_in?: PricingItem::CATEGORY_ORDER)
      .description("Menu category: one of #{PricingItem::CATEGORY_ORDER.join(', ')}")
    required(:name).filled(:string).description("Item name, e.g. 'Gel Manicure'")
    optional(:price).filled(:string).description("Display price, e.g. '$35', '$40+', '+$5'")
    optional(:active).filled(:bool).description("Whether it is live (default true)")
    optional(:position).filled(:integer).description("Sort order (lower first); defaults to appended")
  end

  def call(**attrs)
    item = PricingItem.new(attrs)
    item.position = (PricingItem.maximum(:position) || -1) + 1 unless attrs.key?(:position)
    item.save!
    audit!(action: "create", record: item,
           summary: "Added pricing item '#{item.name}' (#{item.category})",
           details: { after: serialize_pricing_item(item) })
    json(ok: true, pricing_item: serialize_pricing_item(item))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
