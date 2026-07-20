class AddBookableToPricingItemsAndTeamMembers < ActiveRecord::Migration[8.0]
  # Only longer, higher-value services take online bookings; short/add-on work
  # (polish changes, repairs, trims, waxing) stays walk-in so it doesn't
  # fragment the schedule. Technicians opt in individually — the team is used to
  # pen-and-paper booking. Defaults to false so nothing becomes bookable by
  # accident. See docs/service-menu-reconciliation.md.
  def change
    add_column :pricing_items, :bookable, :boolean, default: false, null: false
    add_column :team_members, :bookable, :boolean, default: false, null: false
  end
end
