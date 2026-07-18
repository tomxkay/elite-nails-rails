class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.string :author_name, null: false
      t.integer :rating, null: false, default: 5
      t.text :quote
      t.string :source
      t.string :relative_date
      t.boolean :featured, null: false, default: false
      t.boolean :approved, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :reviews, [:approved, :position]
  end
end
