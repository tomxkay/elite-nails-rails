require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :success
  end

  # The hero once advertised "200+ hues" (never counted), "breathable polishes"
  # (a real product category the salon does not stock) and "private seating"
  # (there is none — the private room is for waxing only). They were removed on
  # 2026-07-21. Every hero claim must be something the owner has confirmed, so
  # this fails loudly if any of them is reinstated.
  test "home page makes no unverified product or facility claims" do
    get root_url
    assert_response :success

    {
      "200+ hues" => "the colour count was never verified",
      "Breathable polishes" => "the salon does not stock breathable polish",
      "Private seating" => "there is no private seating on the salon floor",
      "hospital-grade" => "a specific regulatory product claim the owner has not confirmed",
      "spa treatments" => "no spa treatment has ever been on the menu"
    }.each do |claim, reason|
      assert_no_match(/#{Regexp.escape(claim)}/i, response.body,
        "Removed claim is back on the home page: #{claim.inspect} — #{reason}. " \
        "Confirm with the owner before re-adding it.")
    end
  end

  test "home page shows the verified hero claims" do
    get root_url

    assert_match "Since 2002", response.body
    assert_match "Call ahead", response.body
    assert_match "Private Waxing Room", response.body
    assert_match "Done in our private waxing room", response.body
  end

  # The footer carries the salon's NAP because that's where people look for it,
  # and consistent name/address/phone across the page supports local search.
  test "footer carries tappable contact details and hours" do
    get root_url

    assert_select "footer address a[href=?]", "tel:#{SiteSetting.current.phone}"
    assert_select "footer address a[href*=?]", "maps.google"
    assert_select "footer" do
      assert_select "dt", minimum: 1, text: /Mon|Sat|Sun/
    end
    assert_match(/#{Date.current.year}/, response.body)
  end

  test "footer does not link the retired gallery section" do
    get root_url

    assert_select "footer a[href*=?]", "gallery", count: 0
  end

  # Online booking covers one technician and a subset of the menu, so the FAQ
  # must not promise that booking ahead secures a particular technician — only a
  # phone call can. See docs/booking-adoption-notes.md.
  test "faq does not promise technician choice through online booking" do
    get root_url

    assert_no_match(/guarantees your preferred time and technician/i, response.body)
    assert_match(/only way to request a particular technician/i, response.body)
  end

  test "renders the primary promotion banner" do
    Promotion.create!(
      title: "Summer Hands",
      deal: "20% Off",
      badge: "Limited Time",
      fine_print: "This week only.",
      featured: true,
      position: 0
    )

    get root_url

    assert_response :success
    assert_select "header", text: /Current Special/
    assert_select "header", text: /20% Off Summer Hands/
    assert_select "header", text: /Limited Time/
  end

  test "does not render the promotion banner when no persisted promotion is visible" do
    Promotion.create!(title: "Paused Special", active: false)

    get root_url

    assert_response :success
    assert_select "header", text: /Current Special/, count: 0
  end
end
