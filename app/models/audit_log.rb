class AuditLog < ApplicationRecord
  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # Record a content change. `details` captures a before/after snapshot so any
  # change made via MCP (or elsewhere) is reversible by inspection.
  def self.record!(action:, record:, summary:, source: "mcp", details: {})
    create!(
      action: action,
      record_type: record.class.name,
      record_id: record.id,
      summary: summary,
      source: source,
      details: details
    )
  end
end
