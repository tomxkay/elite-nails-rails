# frozen_string_literal: true

namespace :content do
  # Menu content only. Deliberately does NOT touch Review, Promotion,
  # SiteSetting or BusinessHour — those can hold owner-entered content that
  # exists nowhere in code, so truncating them would destroy real data.
  # Named as strings: the task file loads before the Rails env, so the model
  # constants don't exist yet at this point.
  MENU_MODEL_NAMES = %w[Service PricingItem TeamMember].freeze

  desc "Hard-reset menu content (services, pricing items, team members) from model DEFAULTS. " \
       "TRUNCATEs and restarts id sequences. In production requires FORCE=1."
  task reset_menu: :environment do
    if Rails.env.production? && ENV["FORCE"] != "1"
      abort "Refusing to truncate in production without FORCE=1. Re-run with FORCE=1 if you mean it."
    end

    models = MENU_MODEL_NAMES.map(&:constantize)
    tables = models.map { |m| m.connection.quote_table_name(m.table_name) }

    models.each { |m| puts "  before  #{m.table_name}: #{m.count}" }

    # RESTART IDENTITY resets the id sequences so the reseed starts at 1.
    ActiveRecord::Base.connection.execute(
      "TRUNCATE TABLE #{tables.join(', ')} RESTART IDENTITY CASCADE"
    )

    models.each do |model|
      model::DEFAULTS.each { |attrs| model.create!(attrs) }
      puts "  after   #{model.table_name}: #{model.count} (ids #{model.minimum(:id)}..#{model.maximum(:id)})"
    end

    puts "Menu content reset."
  end

  desc "Export services to CSV for Square's service-library import " \
       "(name, description, duration, price). ALL=1 includes walk-in-only " \
       "services; by default only bookable ones are exported."
  task square_csv: :environment do
    require "csv"

    scope = ENV["ALL"] == "1" ? PricingItem.visible : PricingItem.visible.where(bookable: true)
    items = scope.ordered

    path = Rails.root.join("tmp", "square-services.csv")
    FileUtils.mkdir_p(path.dirname)

    CSV.open(path, "w") do |csv|
      csv << [ "Service name", "Service description", "Service duration", "Service price" ]
      items.each do |item|
        # Square wants a bare number for price; our display strings carry "$"
        # and sometimes a "+" (variable pricing) that has to come off.
        csv << [
          item.name,
          item.description,
          item.duration_minutes,
          item.price.to_s.delete("$+").strip
        ]
      end
    end

    puts "Wrote #{items.size} services to #{path}"
    puts "Square caps imports at 100 services." if items.size > 100
  end
end
