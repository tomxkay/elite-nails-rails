# frozen_string_literal: true

class ListServicesTool < ApplicationTool
  description "List the salon's services (the marketing cards on the site) with all " \
              "fields and status. Use this before editing so you reference the correct id."

  annotations(
    title: "List services",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:only_active).filled(:bool)
      .description("If true, only return services currently visible on the site")
  end

  def call(only_active: false)
    scope = only_active ? Service.visible : Service.all
    json(scope.ordered.map { |s| serialize_service(s) })
  end
end
