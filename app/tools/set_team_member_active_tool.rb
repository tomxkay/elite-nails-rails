# frozen_string_literal: true

class SetTeamMemberActiveTool < ApplicationTool
  description "Show or hide a team member without deleting them. Set active: false to " \
              "take them off the website (reversible), or active: true to bring them back."

  annotations(
    title: "Show/hide team member",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Team member id (from ListTeamMembersTool)")
    required(:active).filled(:bool).description("true = visible, false = hidden")
  end

  def call(id:, active:)
    member = TeamMember.find_by(id: id)
    return json(ok: false, error: "No team member with id #{id}") unless member

    member.update!(active: active)
    audit!(action: "set_active", record: member,
           summary: "#{active ? 'Showed' : 'Hid'} team member '#{member.name}'",
           details: { active: active })
    json(ok: true, team_member: serialize_team_member(member))
  end
end
