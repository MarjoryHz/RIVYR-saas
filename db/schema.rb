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

ActiveRecord::Schema[8.1].define(version: 2026_03_10_142641) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "candidates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "cv_id", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "linkedin_url"
    t.text "notes"
    t.string "phone"
    t.string "source"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["cv_id"], name: "index_candidates_on_cv_id"
  end

  create_table "client_contacts", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "job_title"
    t.string "last_name"
    t.string "phone"
    t.boolean "primary_contact"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_contacts_on_client_id"
  end

  create_table "clients", force: :cascade do |t|
    t.boolean "active"
    t.text "bio"
    t.string "brand_name"
    t.string "company_size"
    t.datetime "created_at", null: false
    t.string "legal_name"
    t.text "location"
    t.string "ownership_type"
    t.string "sector"
    t.datetime "updated_at", null: false
    t.string "website_url"
  end

  create_table "commissions", force: :cascade do |t|
    t.boolean "client_payment_required"
    t.string "commission_rule"
    t.datetime "created_at", null: false
    t.date "eligible_for_invoicing_at"
    t.integer "freelancer_share_cents"
    t.integer "gross_amount_cents"
    t.bigint "placement_id", null: false
    t.integer "rivyr_share_cents"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["placement_id"], name: "index_commissions_on_placement_id"
  end

  create_table "cvs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_name"
    t.string "file_type"
    t.string "file_url"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "freelancer_profiles", force: :cascade do |t|
    t.string "availability_status"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "linkedin_url"
    t.string "operational_status"
    t.boolean "profile_private"
    t.bigint "region_id", null: false
    t.integer "rivyr_score_current"
    t.bigint "specialty_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "website_url"
    t.index ["region_id"], name: "index_freelancer_profiles_on_region_id"
    t.index ["specialty_id"], name: "index_freelancer_profiles_on_specialty_id"
    t.index ["user_id"], name: "index_freelancer_profiles_on_user_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "amount_cents"
    t.datetime "created_at", null: false
    t.string "invoice_type"
    t.date "issue_date"
    t.string "number"
    t.date "paid_date"
    t.bigint "placement_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["placement_id"], name: "index_invoices_on_placement_id"
  end

  create_table "missions", force: :cascade do |t|
    t.text "brief_summary"
    t.bigint "client_contact_id", null: false
    t.bigint "client_id", null: false
    t.date "closed_at"
    t.text "compensation_summary"
    t.boolean "contract_signed"
    t.datetime "created_at", null: false
    t.bigint "freelancer_profile_id", null: false
    t.text "location"
    t.string "mission_type"
    t.date "opened_at"
    t.string "origin_type"
    t.string "priority_level"
    t.string "reference"
    t.bigint "region_id", null: false
    t.text "search_constraints"
    t.bigint "specialty_id", null: false
    t.date "started_at"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["client_contact_id"], name: "index_missions_on_client_contact_id"
    t.index ["client_id"], name: "index_missions_on_client_id"
    t.index ["freelancer_profile_id"], name: "index_missions_on_freelancer_profile_id"
    t.index ["region_id"], name: "index_missions_on_region_id"
    t.index ["specialty_id"], name: "index_missions_on_specialty_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents"
    t.bigint "commission_id", null: false
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.datetime "paid_at"
    t.string "payment_type"
    t.string "reference"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["commission_id"], name: "index_payments_on_commission_id"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "placements", force: :cascade do |t|
    t.integer "annual_salary_cents"
    t.bigint "candidate_id", null: false
    t.datetime "created_at", null: false
    t.date "hired_at"
    t.bigint "mission_id", null: false
    t.text "notes"
    t.integer "placement_fee_cents"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_placements_on_candidate_id"
    t.index ["mission_id"], name: "index_placements_on_mission_id"
  end

  create_table "regions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "options", default: [], array: true
    t.datetime "updated_at", null: false
  end

  create_table "specialties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "options", default: [], array: true
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "candidates", "cvs"
  add_foreign_key "client_contacts", "clients"
  add_foreign_key "commissions", "placements"
  add_foreign_key "freelancer_profiles", "regions"
  add_foreign_key "freelancer_profiles", "specialties"
  add_foreign_key "freelancer_profiles", "users"
  add_foreign_key "invoices", "placements"
  add_foreign_key "missions", "client_contacts"
  add_foreign_key "missions", "clients"
  add_foreign_key "missions", "freelancer_profiles"
  add_foreign_key "missions", "regions"
  add_foreign_key "missions", "specialties"
  add_foreign_key "payments", "commissions"
  add_foreign_key "payments", "invoices"
  add_foreign_key "placements", "candidates"
  add_foreign_key "placements", "missions"
end
