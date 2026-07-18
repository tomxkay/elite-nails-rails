class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string :title, null: false
      t.text :description
      t.string :image
      t.string :pricing_category
      t.boolean :featured, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :services, [:active, :position]
  end
end
