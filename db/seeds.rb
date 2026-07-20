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

# Retire cards that left DEFAULTS (see the pricing prune below for rationale).
current_services = Service::DEFAULTS.map { |attrs| attrs[:title] }
retired_services = Service.visible.reject { |s| current_services.include?(s.title) }
retired_services.each { |s| s.update!(active: false) }

puts "Seeded #{Service.visible.count} services (#{retired_services.size} retired)."

# --- Pricing items ---
PricingItem::DEFAULTS.each do |attrs|
  PricingItem.find_or_initialize_by(category: attrs[:category], name: attrs[:name]).update!(attrs)
end

# Retire items that have left DEFAULTS (e.g. the placeholder menu replaced in
# 2026-07). Hidden, not deleted — matches the no-hard-delete convention used by
# the MCP tools, so a mistake here is recoverable.
current = PricingItem::DEFAULTS.map { |attrs| [ attrs[:category], attrs[:name] ] }
retired = PricingItem.visible.reject { |item| current.include?([ item.category, item.name ]) }
retired.each { |item| item.update!(active: false) }

puts "Seeded #{PricingItem.visible.count} pricing items (#{retired.size} retired)."

# --- Team members ---
TeamMember::DEFAULTS.each do |attrs|
  TeamMember.find_or_initialize_by(name: attrs[:name]).update!(attrs)
end

# Same retire-don't-delete handling as pricing: renaming a member (e.g.
# "Michael K" -> "Michael") upserts a new row and would otherwise leave the old
# one visible alongside it.
current_members = TeamMember::DEFAULTS.map { |attrs| attrs[:name] }
retired_members = TeamMember.visible.reject { |m| current_members.include?(m.name) }
retired_members.each { |m| m.update!(active: false) }

puts "Seeded #{TeamMember.visible.count} team members (#{retired_members.size} retired)."

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
