class CreatePromotions < ActiveRecord::Migration[8.0]
  def change
    create_table :promotions do |t|
      t.string :title, null: false
      t.string :deal
      t.text :description
      t.string :fine_print
      t.string :badge
      t.boolean :featured, null: false, default: false
      t.boolean :active, null: false, default: true
      t.date :starts_on
      t.date :ends_on
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :promotions, [:active, :position]
  end
end
