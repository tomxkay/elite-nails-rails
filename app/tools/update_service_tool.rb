# frozen_string_literal: true

class UpdateServiceTool < ApplicationTool
  description "Update fields on an existing service by id. Only provided fields " \
              "change. Changes appear on the website immediately and are audit-logged."

  annotations(
    title: "Update service",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Service id (from ListServicesTool)")
    optional(:title).filled(:string)
    optional(:description).filled(:string)
    optional(:pricing_category).filled(:string).description("'Hands', 'Feet' or 'Add-Ons'")
    optional(:featured).filled(:bool)
    optional(:active).filled(:bool)
    optional(:position).filled(:integer)
  end

  def call(id:, **attrs)
    service = Service.find_by(id: id)
    return json(ok: false, error: "No service with id #{id}") unless service

    before = serialize_service(service)
    service.update!(attrs)
    audit!(action: "update", record: service,
           summary: "Updated service '#{service.title}' (#{attrs.keys.join(', ')})",
           details: { before: before, after: serialize_service(service) })
    json(ok: true, service: serialize_service(service))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
