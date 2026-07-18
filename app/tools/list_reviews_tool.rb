# frozen_string_literal: true

class ListReviewsTool < ApplicationTool
  description "List client reviews/testimonials with all fields and status. " \
              "Use this before editing so you reference the correct id."

  annotations(
    title: "List reviews",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:only_approved).filled(:bool)
      .description("If true, only return reviews currently shown on the site")
  end

  def call(only_approved: false)
    scope = only_approved ? Review.visible : Review.all
    json(scope.ordered.map { |r| serialize_review(r) })
  end
end
