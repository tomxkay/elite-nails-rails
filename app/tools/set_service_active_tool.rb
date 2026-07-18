# frozen_string_literal: true

class SetServiceActiveTool < ApplicationTool
  description "Show or hide a service without deleting it. Set active: false to " \
              "take it off the website (reversible), or active: true to bring it back."

  annotations(
    title: "Show/hide service",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Service id (from ListServicesTool)")
    required(:active).filled(:bool).description("true = visible, false = hidden")
  end

  def call(id:, active:)
    service = Service.find_by(id: id)
    return json(ok: false, error: "No service with id #{id}") unless service

    service.update!(active: active)
    audit!(action: "set_active", record: service,
           summary: "#{active ? 'Showed' : 'Hid'} service '#{service.title}'",
           details: { active: active })
    json(ok: true, service: serialize_service(service))
  end
end
