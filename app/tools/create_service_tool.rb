# frozen_string_literal: true

class CreateServiceTool < ApplicationTool
  description "Create a new service card. It appears on the website immediately. " \
              "Photos are developer-managed asset files, so new services render " \
              "with a placeholder image until one is added."

  annotations(
    title: "Create service",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:title).filled(:string).description("Display title, e.g. 'Gel Manicures'")
    optional(:description).filled(:string).description("One or two sentences describing the service")
    optional(:pricing_category).filled(:string)
      .description("Pricing menu category this links to: 'Hands', 'Feet' or 'Add-Ons'")
    optional(:featured).filled(:bool).description("Whether to visually feature this card")
    optional(:active).filled(:bool).description("Whether it is live (default true)")
    optional(:position).filled(:integer).description("Sort order (lower first); defaults to appended")
  end

  def call(**attrs)
    service = Service.new(attrs)
    service.position = (Service.maximum(:position) || -1) + 1 unless attrs.key?(:position)
    service.save!
    audit!(action: "create", record: service,
           summary: "Created service '#{service.title}'",
           details: { after: serialize_service(service) })
    json(ok: true, service: serialize_service(service))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
