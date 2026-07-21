require "test_helper"

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
