require "test_helper"

class Analytics::SummaryTest < ActiveSupport::TestCase
  test "computes visits, conversion, funnel, sources and devices in the window" do
    v1 = create_visit(referring_domain: "google.com", device_type: "Mobile")
    v2 = create_visit(referring_domain: "instagram.com", device_type: "Desktop")
    create_visit(referring_domain: nil, device_type: "Mobile") # direct, no events

    track(v1, "book_page_opened")
    track(v1, "service_selected")
    track(v1, "booking_completed")

    track(v2, "book_page_opened")
    track(v2, "service_selected")

    summary = Analytics::Summary.new(since: 1.day.ago, till: 1.day.from_now)

    assert_equal 3, summary.visits
    assert_equal 3, summary.unique_visitors
    assert_equal 1, summary.bookings
    assert_in_delta 33.33, summary.conversion_rate, 0.05
    assert_equal 2, summary.funnel["book_page_opened"]
    assert_equal 2, summary.funnel["service_selected"]
    assert_equal 1, summary.funnel["booking_completed"]
    assert_equal({ "google.com" => 1, "instagram.com" => 1, "(direct)" => 1 }, summary.top_sources)
    assert_equal({ "Mobile" => 2, "Desktop" => 1 }, summary.device_breakdown)
  end

  test "funnel_dropoff reports the percentage lost between steps" do
    # 5 visits open the booking page; only 1 goes on to pick a service.
    5.times do |i|
      visit = create_visit
      track(visit, "book_page_opened")
      track(visit, "service_selected") if i.zero?
    end

    dropoff = Analytics::Summary.new(since: 1.day.ago).funnel_dropoff
    assert_in_delta 80.0, dropoff["service_selected"], 0.1 # 4 of 5 dropped
  end

  test "excludes visits and events outside the window" do
    old = create_visit(started_at: 60.days.ago)
    track(old, "booking_completed", time: 60.days.ago)

    summary = Analytics::Summary.new(since: 30.days.ago)
    assert_equal 0, summary.visits
    assert_equal 0, summary.bookings
    assert_equal 0.0, summary.conversion_rate
  end

  private

  def create_visit(started_at: Time.current, **attrs)
    Ahoy::Visit.create!(
      visit_token: SecureRandom.uuid,
      visitor_token: SecureRandom.uuid,
      started_at: started_at,
      **attrs
    )
  end

  def track(visit, name, time: Time.current)
    Ahoy::Event.create!(visit: visit, name: name, time: time, properties: {})
  end
end
