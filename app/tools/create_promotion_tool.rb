# frozen_string_literal: true

class CreatePromotionTool < ApplicationTool
  description "Create a new promotion/special. It appears on the website immediately. " \
              "Set featured: true for the large hero offer; others render as coupon cards."

  annotations(
    title: "Create promotion",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:title).filled(:string).description("Internal + display title, e.g. 'Your First Visit'")
    optional(:deal).filled(:string).description("Short deal label, e.g. '15% Off', '$10 Off', 'Free'")
    optional(:description).filled(:string).description("One or two sentences describing the offer")
    optional(:fine_print).filled(:string).description("Small print / conditions")
    optional(:badge).filled(:string).description("Small badge label (featured offers only), e.g. 'New Guests'")
    optional(:featured).filled(:bool).description("Whether this is the large featured offer")
    optional(:active).filled(:bool).description("Whether it is live (default true)")
    optional(:starts_on).filled(:string).description("Start date, ISO YYYY-MM-DD (optional)")
    optional(:ends_on).filled(:string).description("End date, ISO YYYY-MM-DD; auto-hides after this day")
    optional(:position).filled(:integer).description("Sort order (lower first); defaults to appended")
  end

  def call(**attrs)
    promo = Promotion.new(attrs)
    # Append to the end unless the caller set an explicit position (the column
    # defaults to 0, so we can't rely on `||=`).
    promo.position = (Promotion.maximum(:position) || -1) + 1 unless attrs.key?(:position)
    promo.save!
    audit!(action: "create", record: promo,
           summary: "Created promotion '#{promo.title}'",
           details: { after: serialize_promotion(promo) })
    json(ok: true, promotion: serialize_promotion(promo))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
