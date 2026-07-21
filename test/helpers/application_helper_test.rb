require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "linkify_phone turns the salon number into a tel: link" do
    result = linkify_phone("Call us at #{salon.phone_display} today.")

    assert_includes result, %(href="tel:#{salon.phone}")
    assert_includes result, salon.phone_display
    assert_includes result, "Call us at"
    assert_includes result, "today."
  end

  test "linkify_phone leaves text without a phone number alone" do
    result = linkify_phone("Walk-ins are always welcome.")

    assert_equal "Walk-ins are always welcome.", result
    assert_not_includes result, "tel:"
  end

  test "linkify_phone links every occurrence" do
    result = linkify_phone("#{salon.phone_display} or #{salon.phone_display}")

    assert_equal 2, result.scan(/href="tel:/).size
  end

  # The helper marks its output html_safe, so the source text must be escaped
  # first — otherwise any markup that reached an FAQ answer would render.
  test "linkify_phone escapes markup in the source text" do
    result = linkify_phone("<script>alert(1)</script> call #{salon.phone_display}")

    assert_not_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
    assert_includes result, %(href="tel:#{salon.phone}")
  end
end
