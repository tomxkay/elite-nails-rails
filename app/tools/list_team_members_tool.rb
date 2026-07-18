# frozen_string_literal: true

class ListTeamMembersTool < ApplicationTool
  description "List the salon's team members with all fields and status. " \
              "Use this before editing so you reference the correct id."

  annotations(
    title: "List team members",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    optional(:only_active).filled(:bool)
      .description("If true, only return team members currently shown on the site")
  end

  def call(only_active: false)
    scope = only_active ? TeamMember.visible : TeamMember.all
    json(scope.ordered.map { |m| serialize_team_member(m) })
  end
end
