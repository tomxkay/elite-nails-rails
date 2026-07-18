# frozen_string_literal: true

class SetPromotionActiveTool < ApplicationTool
  description "Show or hide a promotion without deleting it. Set active: false to " \
              "take it off the website (reversible), or active: true to bring it back."

  annotations(
    title: "Show/hide promotion",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Promotion id (from list_promotions)")
    required(:active).filled(:bool).description("true = visible, false = hidden")
  end

  def call(id:, active:)
    promo = Promotion.find_by(id: id)
    return json(ok: false, error: "No promotion with id #{id}") unless promo

    promo.update!(active: active)
    audit!(action: "set_active", record: promo,
           summary: "#{active ? 'Showed' : 'Hid'} promotion '#{promo.title}'",
           details: { active: active })
    json(ok: true, promotion: serialize_promotion(promo))
  end
end
