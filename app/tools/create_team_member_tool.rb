# frozen_string_literal: true

class CreateTeamMemberTool < ApplicationTool
  description "Add a team member to the website. They appear immediately. Photos are " \
              "developer-managed asset files, so new members render with a placeholder."

  annotations(
    title: "Add team member",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:name).filled(:string).description("Display name, e.g. 'Michael K'")
    optional(:role).filled(:string).description("Role/title, e.g. 'Owner · Master Technician'")
    optional(:bio).filled(:string).description("Short bio paragraph")
    optional(:quote).filled(:string).description("Personal quote shown on the card")
    optional(:specialties).array(:string).description("List of specialties, e.g. ['Gel X', 'Nail Art']")
    optional(:active).filled(:bool).description("Whether they are shown (default true)")
    optional(:bookable).filled(:bool)
      .description("Whether they take online bookings at /book (default false). Others show a " \
                   "'call to book' CTA instead. They must also be assigned to the service in " \
                   "Square, or their availability will come back empty.")
    optional(:position).filled(:integer).description("Sort order (lower first); defaults to appended")
  end

  def call(**attrs)
    member = TeamMember.new(attrs)
    member.position = (TeamMember.maximum(:position) || -1) + 1 unless attrs.key?(:position)
    member.save!
    audit!(action: "create", record: member,
           summary: "Added team member '#{member.name}'",
           details: { after: serialize_team_member(member) })
    json(ok: true, team_member: serialize_team_member(member))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
