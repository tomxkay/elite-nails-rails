# frozen_string_literal: true

module Analytics
  # Read-side KPI rollups over Ahoy visits + events, for a time window.
  # Owner-facing numbers should be a method call here, not raw SQL scattered
  # around. See docs/analytics-plan.md.
  #
  #   Analytics::Summary.new.overview        # last 30 days
  #   Analytics::Summary.new(since: 7.days.ago).funnel
  class Summary
    # The reliable, server-tracked funnel (client clicks like book_cta_clicked
    # are lossy to ad-blockers, so they're excluded from the core funnel).
    FUNNEL_STEPS = %w[
      book_page_opened
      service_selected
      slot_selected
      booking_submitted
      booking_completed
    ].freeze

    def initialize(since: 30.days.ago, till: Time.current)
      @range = since..till
    end

    def visits
      visits_scope.count
    end

    def unique_visitors
      visits_scope.distinct.count(:visitor_token)
    end

    # Total completed bookings (a single visit could complete more than one).
    def bookings
      events_scope.where(name: "booking_completed").count
    end

    # Visits that resulted in at least one completed booking.
    def converting_visits
      unique_visits_with("booking_completed")
    end

    # Percentage of visits that booked, e.g. 3.5.
    def conversion_rate
      total = visits
      return 0.0 if total.zero?

      (converting_visits.to_f / total * 100).round(2)
    end

    # Per-session funnel: how many distinct visits reached each step.
    def funnel
      FUNNEL_STEPS.index_with { |name| unique_visits_with(name) }
    end

    # Step-to-step drop-off, e.g. { "service_selected" => 26.1 } meaning 26.1%
    # of visits that opened the page never picked a service.
    def funnel_dropoff
      counts = funnel
      FUNNEL_STEPS.each_cons(2).to_h do |from, to|
        base = counts[from]
        pct = base.zero? ? 0.0 : ((base - counts[to]).to_f / base * 100).round(2)
        [ to, pct ]
      end
    end

    # Top referring domains (nil referrer = direct traffic).
    def top_sources(limit: 10)
      visits_scope
        .group(:referring_domain)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(limit)
        .count
        .transform_keys { |domain| domain.presence || "(direct)" }
    end

    def device_breakdown
      visits_scope
        .group(:device_type)
        .count
        .transform_keys { |type| type.presence || "unknown" }
    end

    def overview
      {
        range: { since: @range.begin, till: @range.end },
        visits: visits,
        unique_visitors: unique_visitors,
        bookings: bookings,
        conversion_rate: conversion_rate,
        funnel: funnel,
        funnel_dropoff: funnel_dropoff,
        top_sources: top_sources,
        device_breakdown: device_breakdown
      }
    end

    private

    def visits_scope
      Ahoy::Visit.where(started_at: @range)
    end

    def events_scope
      Ahoy::Event.where(time: @range)
    end

    def unique_visits_with(name)
      events_scope.where(name: name).distinct.count(:visit_id)
    end
  end
end
