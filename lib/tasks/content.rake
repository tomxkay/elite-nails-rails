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

  # Named explicitly rather than "anything not in DEFAULTS" on purpose: a blanket
  # prune would also delete owner-created content (a real promotion added via
  # MCP, a real review). These are the exact rows the 2026-07-21 content audit
  # identified as placeholder/fabricated. Safe to re-run; does nothing once clean.
  FABRICATED_REVIEW_AUTHORS = [
    "Sarah M.", "Jennifer L.", "Michelle R.", "Ana P.", "Karen T.", "Denise W."
  ].freeze

  RETIRED_PROMOTION_TITLES = [
    "Birthday Treat",           # dropped from the menu 2026-07-21
    "Tues–Thurs Gel Special",   # dropped from the menu 2026-07-21
    "Summer Gel Pedicure Special" # test data, confirmed by the owner
  ].freeze

  desc "Remove placeholder content the 2026-07-21 audit found (fabricated reviews, " \
       "retired promotions). Idempotent. Run AFTER db:seed on a deploy."
  task remove_placeholder_content: :environment do
    fabricated = Review.where(author_name: FABRICATED_REVIEW_AUTHORS)
    if fabricated.exists?
      puts "  deleting #{fabricated.count} fabricated review(s): #{fabricated.pluck(:author_name).join(', ')}"
      fabricated.destroy_all
    else
      puts "  no fabricated reviews present"
    end

    # Hidden, not deleted — matches the no-hard-delete convention for content the
    # owner may want back (a seasonal promotion could return next year).
    retired = Promotion.where(title: RETIRED_PROMOTION_TITLES, active: true)
    if retired.exists?
      puts "  hiding #{retired.count} retired promotion(s): #{retired.pluck(:title).join(', ')}"
      retired.each { |promotion| promotion.update!(active: false) }
    else
      puts "  no retired promotions active"
    end

    puts "  now visible: #{Review.visible.count} reviews, #{Promotion.visible.count} promotions"
    puts "  rating: #{SiteSetting.current.aggregate_rating} / #{SiteSetting.current.review_count} reviews"
    puts "Placeholder content cleanup complete."
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
