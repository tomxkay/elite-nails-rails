require "test_helper"
require "minitest/mock"

class ApplicationHelperTest < ActionView::TestCase
  test "linkify_contact turns the salon number into a tel: link" do
    result = linkify_contact("Call us at #{salon.phone_display} today.")

    assert_includes result, %(href="tel:#{salon.phone}")
    assert_includes result, salon.phone_display
    assert_includes result, "Call us at"
    assert_includes result, "today."
  end

  test "linkify_contact leaves text with no contact details alone" do
    result = linkify_contact("Walk-ins are always welcome.")

    assert_equal "Walk-ins are always welcome.", result
    assert_not_includes result, "tel:"
    assert_not_includes result, "maps.google"
  end

  test "linkify_contact turns the street address into a maps link" do
    result = linkify_contact("Find us at #{salon_full_address} in downtown Cramerton.")

    assert_includes result, salon_map_url
    assert_includes result, %(target="_blank")
    assert_includes result, %(rel="noopener")
    assert_includes result, "in downtown Cramerton."
  end

  test "linkify_contact links a phone number and an address in the same string" do
    result = linkify_contact("We're at #{salon_full_address}. Call #{salon.phone_display}.")

    assert_includes result, %(href="tel:#{salon.phone}")
    assert_includes result, salon_map_url
  end

  test "linkify_contact links the booking phrase to the booking flow" do
    stub(:booking_link, "/book") do
      result = linkify_contact("You can also #{ApplicationHelper::BOOKING_PHRASE}.")

      assert_includes result, %(href="/book")
      assert_includes result, "#{ApplicationHelper::BOOKING_PHRASE}</a>"
    end
  end

  test "linkify_contact opens an external booking page in a new tab" do
    stub(:booking_link, "https://squareup.com/appointments/elite-nails") do
      result = linkify_contact("You can also #{ApplicationHelper::BOOKING_PHRASE}.")

      assert_includes result, %(target="_blank")
      assert_includes result, %(rel="noopener")
    end
  end

  # booking_link degrades to a tel: URL when Square isn't configured. Linking
  # the words "book … online" to a phone call would contradict the sentence, so
  # the phrase is left as plain text instead.
  test "linkify_contact leaves the booking phrase unlinked when booking is phone-only" do
    stub(:booking_link, "tel:+17048249032") do
      result = linkify_contact("You can also #{ApplicationHelper::BOOKING_PHRASE}.")

      assert_includes result, ApplicationHelper::BOOKING_PHRASE
      assert_not_includes result, "<a"
    end
  end

  test "linkify_contact links every occurrence" do
    result = linkify_contact("#{salon.phone_display} or #{salon.phone_display}")

    assert_equal 2, result.scan(/href="tel:/).size
  end

  # The helper marks its output html_safe, so the source text must be escaped
  # first — otherwise any markup that reached an FAQ answer would render.
  test "linkify_contact escapes markup in the source text" do
    result = linkify_contact("<script>alert(1)</script> call #{salon.phone_display}")

    assert_not_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
    assert_includes result, %(href="tel:#{salon.phone}")
  end
end
