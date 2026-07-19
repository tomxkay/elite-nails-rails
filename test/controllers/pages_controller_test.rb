require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :success
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
end
