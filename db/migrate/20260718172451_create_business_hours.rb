class CreateBusinessHours < ActiveRecord::Migration[8.0]
  def change
    create_table :business_hours do |t|
      t.integer :wday, null: false
      t.string :opens
      t.string :closes
      t.boolean :closed, null: false, default: false

      t.timestamps
    end

    add_index :business_hours, :wday, unique: true
  end
end
