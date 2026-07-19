class CreateAhoyVisitsAndEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :ahoy_visits do |t|
      t.string :visit_token
      t.string :visitor_token

      # standard (ip is masked — see config/initializers/ahoy.rb)
      t.string :ip
      t.text :user_agent
      t.text :referrer
      t.string :referring_domain
      t.text :landing_page

      # technology
      t.string :browser
      t.string :os
      t.string :device_type

      # location — coarse only (city/region/country). Precise lat/long is
      # intentionally omitted per the anonymized-analytics decision; these stay
      # null until geocoding is enabled later.
      t.string :country
      t.string :region
      t.string :city

      # utm parameters
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_term
      t.string :utm_content
      t.string :utm_campaign

      t.datetime :started_at
    end

    add_index :ahoy_visits, :visit_token, unique: true
    add_index :ahoy_visits, [ :visitor_token, :started_at ]

    create_table :ahoy_events do |t|
      t.references :visit

      t.string :name
      t.jsonb :properties
      t.datetime :time
    end

    add_index :ahoy_events, [ :name, :time ]
    add_index :ahoy_events, :properties, using: :gin, opclass: :jsonb_path_ops
  end
end
