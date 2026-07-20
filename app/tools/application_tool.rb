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
      mobile_headline: promo.mobile_headline,
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

  def serialize_service(service)
    {
      id: service.id,
      title: service.title,
      description: service.description,
      pricing_category: service.pricing_category,
      featured: service.featured,
      active: service.active,
      position: service.position
    }
  end

  def serialize_pricing_item(item)
    {
      id: item.id,
      category: item.category,
      name: item.name,
      price: item.price,
      active: item.active,
      bookable: item.bookable,
      position: item.position
    }
  end

  def serialize_team_member(member)
    {
      id: member.id,
      name: member.name,
      role: member.role,
      bio: member.bio,
      quote: member.quote,
      specialties: member.specialties,
      active: member.active,
      bookable: member.bookable,
      position: member.position
    }
  end

  def serialize_review(review)
    {
      id: review.id,
      author_name: review.author_name,
      rating: review.rating,
      quote: review.quote,
      source: review.source,
      relative_date: review.relative_date,
      featured: review.featured,
      approved: review.approved,
      position: review.position
    }
  end

  def serialize_site_setting(setting)
    {
      name: setting.name,
      phone: setting.phone,
      phone_display: setting.phone_display,
      street: setting.street,
      city: setting.city,
      region: setting.region,
      postal_code: setting.postal_code,
      country: setting.country,
      latitude: setting.latitude&.to_f,
      longitude: setting.longitude&.to_f,
      price_range: setting.price_range,
      established: setting.established,
      aggregate_rating: setting.aggregate_rating&.to_f,
      review_count: setting.review_count
    }
  end

  def serialize_business_hour(hour)
    {
      wday: hour.wday,
      day: hour.day_name,
      opens: hour.opens,
      closes: hour.closes,
      closed: hour.closed,
      display: hour.display_hours
    }
  end

  def json(data)
    JSON.pretty_generate(data)
  end
end
