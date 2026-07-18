class CreateTeamMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :team_members do |t|
      t.string :name, null: false
      t.string :role
      t.text :bio
      t.string :quote
      t.string :image
      t.string :specialties, array: true, null: false, default: []
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :team_members, [:active, :position]
  end
end
