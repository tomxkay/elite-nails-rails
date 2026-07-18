require "test_helper"

class TeamMemberTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not TeamMember.new(name: nil).valid?
    assert TeamMember.new(name: "Michael K").valid?
  end

  test "visible excludes inactive members, ordered by position" do
    TeamMember.create!(name: "Second", position: 1)
    TeamMember.create!(name: "First", position: 0)
    TeamMember.create!(name: "Hidden", active: false)

    assert_equal ["First", "Second"], TeamMember.visible.ordered.map(&:name)
  end

  test "specialties stored as an array" do
    m = TeamMember.create!(name: "Nhan Ka", specialties: ["Gel", "Dip"])
    assert_equal ["Gel", "Dip"], m.reload.specialties
  end

  test "for_display falls back to in-code defaults when empty" do
    assert_equal 0, TeamMember.count

    fallback = TeamMember.for_display
    assert_equal TeamMember::DEFAULTS.map { |d| d[:name] }, fallback.map(&:name)
    assert fallback.none?(&:persisted?)
  end
end
