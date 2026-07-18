class CreatePricingItems < ActiveRecord::Migration[8.0]
  def change
    create_table :pricing_items do |t|
      t.string :category, null: false
      t.string :name, null: false
      t.string :price
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :pricing_items, [:active, :position]
  end
end
