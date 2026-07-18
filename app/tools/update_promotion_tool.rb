# frozen_string_literal: true

class UpdatePromotionTool < ApplicationTool
  description "Update fields on an existing promotion by id. Only provided fields " \
              "change. Changes appear on the website immediately and are audit-logged."

  annotations(
    title: "Update promotion",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Promotion id (from list_promotions)")
    optional(:title).filled(:string)
    optional(:deal).filled(:string)
    optional(:description).filled(:string)
    optional(:fine_print).filled(:string)
    optional(:badge).filled(:string)
    optional(:featured).filled(:bool)
    optional(:active).filled(:bool)
    optional(:starts_on).filled(:string).description("ISO YYYY-MM-DD")
    optional(:ends_on).filled(:string).description("ISO YYYY-MM-DD")
    optional(:position).filled(:integer)
  end

  def call(id:, **attrs)
    promo = Promotion.find_by(id: id)
    return json(ok: false, error: "No promotion with id #{id}") unless promo

    before = serialize_promotion(promo)
    promo.update!(attrs)
    audit!(action: "update", record: promo,
           summary: "Updated promotion '#{promo.title}' (#{attrs.keys.join(', ')})",
           details: { before: before, after: serialize_promotion(promo) })
    json(ok: true, promotion: serialize_promotion(promo))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
