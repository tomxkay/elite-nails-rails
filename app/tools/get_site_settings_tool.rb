# frozen_string_literal: true

class GetSiteSettingsTool < ApplicationTool
  description "Read the salon's site settings: name, phone, address, geo coordinates, " \
              "price range, founding year, and the aggregate review rating shown in SEO data."

  annotations(
    title: "Get site settings",
    read_only_hint: true,
    open_world_hint: false
  )

  def call
    json(serialize_site_setting(SiteSetting.current))
  end
end
