# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_19_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.string "record_type"
    t.integer "record_id"
    t.string "summary"
    t.string "source", default: "mcp", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["record_type", "record_id"], name: "index_audit_logs_on_record_type_and_record_id"
  end

  create_table "business_hours", force: :cascade do |t|
    t.integer "wday", null: false
    t.string "opens"
    t.string "closes"
    t.boolean "closed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wday"], name: "index_business_hours_on_wday", unique: true
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret"
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "pricing_items", force: :cascade do |t|
    t.string "category", null: false
    t.string "name", null: false
    t.string "price"
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_pricing_items_on_active_and_position"
  end

  create_table "promotions", force: :cascade do |t|
    t.string "title", null: false
    t.string "deal"
    t.text "description"
    t.string "fine_print"
    t.string "badge"
    t.boolean "featured", default: false, null: false
    t.boolean "active", default: true, null: false
    t.date "starts_on"
    t.date "ends_on"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mobile_headline"
    t.index ["active", "position"], name: "index_promotions_on_active_and_position"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "author_name", null: false
    t.integer "rating", default: 5, null: false
    t.text "quote"
    t.string "source"
    t.string "relative_date"
    t.boolean "featured", default: false, null: false
    t.boolean "approved", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved", "position"], name: "index_reviews_on_approved_and_position"
  end

  create_table "services", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "image"
    t.string "pricing_category"
    t.boolean "featured", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_services_on_active_and_position"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone"
    t.string "phone_display"
    t.string "street"
    t.string "city"
    t.string "region"
    t.string "postal_code"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "price_range"
    t.integer "established"
    t.decimal "aggregate_rating", precision: 2, scale: 1
    t.integer "review_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "square_credentials", force: :cascade do |t|
    t.string "environment", null: false
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.string "merchant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["environment"], name: "index_square_credentials_on_environment", unique: true
  end

  create_table "team_members", force: :cascade do |t|
    t.string "name", null: false
    t.string "role"
    t.text "bio"
    t.string "quote"
    t.string "image"
    t.string "specialties", default: [], null: false, array: true
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_team_members_on_active_and_position"
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
