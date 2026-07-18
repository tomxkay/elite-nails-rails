# frozen_string_literal: true

class ListPricingItemsTool < ApplicationTool
  description "List the pricing menu items (grouped into the categories " \
              "#{PricingItem::CATEGORY_ORDER.join(', ')}) with all fields and status. " \
              "Use this before editing so you reference the correct id."

  annotations(
    title: "List pricing",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:only_active).filled(:bool)
      .description("If true, only return items currently visible on the site")
  end

  def call(only_active: false)
    scope = only_active ? PricingItem.visible : PricingItem.all
    json(scope.ordered.map { |i| serialize_pricing_item(i) })
  end
end
