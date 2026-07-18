# frozen_string_literal: true

class CreateReviewTool < ApplicationTool
  description "Add a client review/testimonial. It appears on the website immediately " \
              "unless approved: false. Only add genuine reviews from real clients."

  annotations(
    title: "Add review",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:author_name).filled(:string).description("Client's display name, e.g. 'Sarah M.'")
    optional(:rating).filled(:integer, gteq?: 1, lteq?: 5).description("Star rating 1-5 (default 5)")
    optional(:quote).filled(:string).description("The review text")
    optional(:source).filled(:string).description("Where it came from, e.g. 'Google'")
    optional(:relative_date).filled(:string).description("Human date label, e.g. '2 weeks ago'")
    optional(:featured).filled(:bool).description("Whether to visually feature this review")
    optional(:approved).filled(:bool).description("Whether it is shown (default true)")
    optional(:position).filled(:integer).description("Sort order (lower first); defaults to appended")
  end

  def call(**attrs)
    review = Review.new(attrs)
    review.position = (Review.maximum(:position) || -1) + 1 unless attrs.key?(:position)
    review.save!
    audit!(action: "create", record: review,
           summary: "Added review from '#{review.author_name}'",
           details: { after: serialize_review(review) })
    json(ok: true, review: serialize_review(review))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
