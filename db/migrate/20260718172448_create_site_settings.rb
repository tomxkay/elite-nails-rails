class CreateSiteSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :site_settings do |t|
      t.string :name, null: false
      t.string :phone
      t.string :phone_display
      t.string :street
      t.string :city
      t.string :region
      t.string :postal_code
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :price_range
      t.integer :established
      t.decimal :aggregate_rating, precision: 2, scale: 1
      t.integer :review_count

      t.timestamps
    end
  end
end
