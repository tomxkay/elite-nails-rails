class AddDescriptionAndDurationToPricingItems < ActiveRecord::Migration[8.0]
  # Descriptions are stored for every item, including walk-in-only ones, so the
  # menu is complete if we later surface them on the site.
  #
  # duration_minutes exists because Square's service import requires a duration
  # per service — keeping it here makes the CSV export a query rather than a
  # hardcoded list. See lib/tasks/content.rake (content:square_csv).
  def change
    add_column :pricing_items, :description, :text
    add_column :pricing_items, :duration_minutes, :integer
  end
end
