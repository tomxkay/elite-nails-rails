class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.string :action, null: false
      t.string :record_type
      t.integer :record_id
      t.string :summary
      t.string :source, null: false, default: "mcp"
      t.jsonb :details, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, [:record_type, :record_id]
    add_index :audit_logs, :created_at
  end
end
