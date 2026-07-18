# frozen_string_literal: true

class SetReviewApprovedTool < ApplicationTool
  description "Show or hide a review without deleting it. Set approved: false to take " \
              "it off the website (reversible), or approved: true to bring it back."

  annotations(
    title: "Show/hide review",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Review id (from ListReviewsTool)")
    required(:approved).filled(:bool).description("true = visible, false = hidden")
  end

  def call(id:, approved:)
    review = Review.find_by(id: id)
    return json(ok: false, error: "No review with id #{id}") unless review

    review.update!(approved: approved)
    audit!(action: "set_approved", record: review,
           summary: "#{approved ? 'Showed' : 'Hid'} review from '#{review.author_name}'",
           details: { approved: approved })
    json(ok: true, review: serialize_review(review))
  end
end
