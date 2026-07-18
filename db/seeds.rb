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
