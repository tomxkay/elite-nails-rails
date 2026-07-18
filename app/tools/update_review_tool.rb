# frozen_string_literal: true

class UpdateReviewTool < ApplicationTool
  description "Update fields on a review by id (e.g. feature it, fix a typo). Only " \
              "provided fields change. Changes appear immediately and are audit-logged."

  annotations(
    title: "Update review",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Review id (from ListReviewsTool)")
    optional(:author_name).filled(:string)
    optional(:rating).filled(:integer, gteq?: 1, lteq?: 5)
    optional(:quote).filled(:string)
    optional(:source).filled(:string)
    optional(:relative_date).filled(:string)
    optional(:featured).filled(:bool)
    optional(:approved).filled(:bool)
    optional(:position).filled(:integer)
  end

  def call(id:, **attrs)
    review = Review.find_by(id: id)
    return json(ok: false, error: "No review with id #{id}") unless review

    before = serialize_review(review)
    review.update!(attrs)
    audit!(action: "update", record: review,
           summary: "Updated review from '#{review.author_name}' (#{attrs.keys.join(', ')})",
           details: { before: before, after: serialize_review(review) })
    json(ok: true, review: serialize_review(review))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
