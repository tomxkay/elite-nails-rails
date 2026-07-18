# frozen_string_literal: true

class ApplicationTool < ActionTool::Base
  private

  # Log a content change made through MCP, with a before/after snapshot so any
  # change is reversible by inspection.
  def audit!(action:, record:, summary:, details: {})
    AuditLog.record!(action: action, record: record, summary: summary, source: "mcp", details: details)
  end

  def serialize_promotion(promo)
    {
      id: promo.id,
      title: promo.title,
      deal: promo.deal,
      description: promo.description,
      fine_print: promo.fine_print,
      badge: promo.badge,
      featured: promo.featured,
      active: promo.active,
      starts_on: promo.starts_on&.iso8601,
      ends_on: promo.ends_on&.iso8601,
      position: promo.position
    }
  end

  def json(data)
    JSON.pretty_generate(data)
  end
end
