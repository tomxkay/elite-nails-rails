# frozen_string_literal: true

class UpdateTeamMemberTool < ApplicationTool
  description "Update fields on a team member by id. Only provided fields change. " \
              "Changes appear on the website immediately and are audit-logged."

  annotations(
    title: "Update team member",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:id).filled(:integer).description("Team member id (from ListTeamMembersTool)")
    optional(:name).filled(:string)
    optional(:role).filled(:string)
    optional(:bio).filled(:string)
    optional(:quote).filled(:string)
    optional(:specialties).array(:string).description("Replaces the full specialties list")
    optional(:active).filled(:bool)
    optional(:bookable).filled(:bool)
      .description("Whether they take online bookings at /book. They must also be assigned to the " \
                   "service in Square, or their availability will come back empty.")
    optional(:position).filled(:integer)
  end

  def call(id:, **attrs)
    member = TeamMember.find_by(id: id)
    return json(ok: false, error: "No team member with id #{id}") unless member

    before = serialize_team_member(member)
    member.update!(attrs)
    audit!(action: "update", record: member,
           summary: "Updated team member '#{member.name}' (#{attrs.keys.join(', ')})",
           details: { before: before, after: serialize_team_member(member) })
    json(ok: true, team_member: serialize_team_member(member))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
