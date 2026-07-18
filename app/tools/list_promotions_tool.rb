# frozen_string_literal: true

class ListPromotionsTool < ApplicationTool
  description "List the salon's promotions/specials with all fields and status. " \
              "Use this before editing so you reference the correct promotion id."

  annotations(
    title: "List promotions",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:only_active).filled(:bool)
      .description("If true, only return promotions currently visible on the site")
  end

  def call(only_active: false)
    scope = only_active ? Promotion.visible : Promotion.all
    json(scope.ordered.map { |p| serialize_promotion(p) })
  end
end
