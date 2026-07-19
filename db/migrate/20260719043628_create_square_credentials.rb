class CreateSquareCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :square_credentials do |t|
      t.string :environment, null: false, index: { unique: true }
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.string :merchant_id

      t.timestamps
    end
  end
end
