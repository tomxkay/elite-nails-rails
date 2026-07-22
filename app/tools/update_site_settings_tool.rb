# frozen_string_literal: true

class UpdateSiteSettingsTool < ApplicationTool
  description "Update the salon's site settings (name, phone, address, price range, " \
              "aggregate rating…). Only provided fields change. ⚠️ These feed the " \
              "contact section, footer, SEO meta tags and JSON-LD — double-check values."

  annotations(
    title: "Update site settings",
    read_only_hint: false,
    destructive_hint: false,
    open_world_hint: false
  )

  arguments do
    optional(:name).filled(:string).description("Salon display name")
    optional(:phone).filled(:string).description("E.164 phone for tel: links, e.g. '+17048249032'")
    optional(:phone_display).filled(:string).description("Human-formatted phone, e.g. '(704) 824-9032'")
    optional(:street).filled(:string)
    optional(:city).filled(:string)
    optional(:region).filled(:string).description("State/region code, e.g. 'NC'")
    optional(:postal_code).filled(:string)
    optional(:country).filled(:string).description("Country code, e.g. 'US'")
    optional(:latitude).filled(:float)
    optional(:longitude).filled(:float)
    optional(:price_range).filled(:string).description("e.g. '$$'")
    optional(:established).filled(:integer).description("Founding year, e.g. 2003")
    optional(:aggregate_rating).filled(:float).description("Average review rating, e.g. 4.9")
    optional(:review_count).filled(:integer).description("Total number of reviews")
  end

  def call(**attrs)
    setting = SiteSetting.first || SiteSetting.new(SiteSetting::DEFAULTS)
    before = serialize_site_setting(setting)
    setting.update!(attrs)
    audit!(action: "update", record: setting,
           summary: "Updated site settings (#{attrs.keys.join(', ')})",
           details: { before: before, after: serialize_site_setting(setting) })
    json(ok: true, site_settings: serialize_site_setting(setting))
  rescue ActiveRecord::RecordInvalid => e
    json(ok: false, error: e.message)
  end
end
