# Idempotent seeds. Content is sourced from each model's in-code DEFAULTS backup,
# so seeding never loses the canonical data even after the migration to the DB.

# --- Promotions ---
Promotion::DEFAULTS.each do |attrs|
  Promotion.find_or_initialize_by(title: attrs[:title]).update!(attrs)
end
puts "Seeded #{Promotion.count} promotions."

# --- Services ---
Service::DEFAULTS.each do |attrs|
  Service.find_or_initialize_by(title: attrs[:title]).update!(attrs)
end
puts "Seeded #{Service.count} services."

# --- Pricing items ---
PricingItem::DEFAULTS.each do |attrs|
  PricingItem.find_or_initialize_by(category: attrs[:category], name: attrs[:name]).update!(attrs)
end
puts "Seeded #{PricingItem.count} pricing items."

# --- Team members ---
TeamMember::DEFAULTS.each do |attrs|
  TeamMember.find_or_initialize_by(name: attrs[:name]).update!(attrs)
end
puts "Seeded #{TeamMember.count} team members."

# --- Reviews ---
Review::DEFAULTS.each do |attrs|
  Review.find_or_initialize_by(author_name: attrs[:author_name], quote: attrs[:quote]).update!(attrs)
end
puts "Seeded #{Review.count} reviews."

# --- Site settings (singleton) ---
(SiteSetting.first || SiteSetting.new).update!(SiteSetting::DEFAULTS)
puts "Seeded site settings for #{SiteSetting.current.name}."

# --- Business hours ---
BusinessHour::DEFAULTS.each do |attrs|
  BusinessHour.find_or_initialize_by(wday: attrs[:wday]).update!(attrs)
end
puts "Seeded #{BusinessHour.count} business-hour rows."
