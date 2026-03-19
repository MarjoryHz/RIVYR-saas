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

ActiveRecord::Schema[8.1].define(version: 2026_03_19_135500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "candidate_notes", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "candidate_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["candidate_id"], name: "index_candidate_notes_on_candidate_id"
    t.index ["user_id"], name: "index_candidate_notes_on_user_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.string "availability"
    t.string "contract_types", default: [], array: true
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "job_titles", default: [], array: true
    t.jsonb "languages", default: []
    t.string "last_name"
    t.string "linkedin_url"
    t.string "location"
    t.string "mobility_zone"
    t.text "notes"
    t.string "phone"
    t.string "salary_range"
    t.string "skills", default: [], array: true
    t.string "source"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "website_url"
    t.index ["user_id"], name: "index_candidates_on_user_id", unique: true, where: "(user_id IS NOT NULL)"
  end

  create_table "client_contacts", force: :cascade do |t|
    t.string "avatar"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "job_title"
    t.string "last_name"
    t.string "phone"
    t.boolean "primary_contact"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["client_id"], name: "index_client_contacts_on_client_id"
    t.index ["user_id"], name: "index_client_contacts_on_user_id", unique: true, where: "(user_id IS NOT NULL)"
  end

  create_table "client_highlights", force: :cascade do |t|
    t.text "body"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_highlights_on_client_id"
  end

  create_table "client_post_comments", force: :cascade do |t|
    t.text "body"
    t.bigint "client_post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_post_id"], name: "index_client_post_comments_on_client_post_id"
    t.index ["user_id"], name: "index_client_post_comments_on_user_id"
  end

  create_table "client_post_reactions", force: :cascade do |t|
    t.bigint "client_post_id", null: false
    t.datetime "created_at", null: false
    t.string "emoji"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_post_id"], name: "index_client_post_reactions_on_client_post_id"
    t.index ["user_id"], name: "index_client_post_reactions_on_user_id"
  end

  create_table "client_posts", force: :cascade do |t|
    t.text "body"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "media_url"
    t.string "post_type"
    t.datetime "published_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_posts_on_client_id"
  end

  create_table "client_subscriptions", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_id"], name: "index_client_subscriptions_on_client_id"
    t.index ["user_id", "client_id"], name: "index_client_subscriptions_on_user_id_and_client_id", unique: true
    t.index ["user_id"], name: "index_client_subscriptions_on_user_id"
  end

  create_table "client_values", force: :cascade do |t|
    t.text "body"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_values_on_client_id"
  end

  create_table "clients", force: :cascade do |t|
    t.boolean "active"
    t.text "ambiance"
    t.text "bio"
    t.string "brand_name"
    t.string "company_size"
    t.datetime "created_at", null: false
    t.integer "founded_year"
    t.string "legal_name"
    t.text "location"
    t.string "logo"
    t.string "ownership_type"
    t.string "revenue"
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

  create_table "contributions", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.text "question"
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_contributions_on_candidate_id"
  end

  create_table "educations", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "end_month"
    t.integer "end_year"
    t.string "institution"
    t.integer "position", default: 0
    t.integer "start_month"
    t.integer "start_year"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_educations_on_candidate_id"
  end

  create_table "favorite_candidates", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.datetime "created_at", null: false
    t.bigint "mission_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["candidate_id"], name: "index_favorite_candidates_on_candidate_id"
    t.index ["mission_id"], name: "index_favorite_candidates_on_mission_id"
    t.index ["user_id", "candidate_id", "mission_id"], name: "index_favorite_candidates_uniqueness", unique: true
    t.index ["user_id"], name: "index_favorite_candidates_on_user_id"
  end

  create_table "favorite_missions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "mission_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["mission_id"], name: "index_favorite_missions_on_mission_id"
    t.index ["user_id", "mission_id"], name: "index_favorite_missions_on_user_id_and_mission_id", unique: true
    t.index ["user_id"], name: "index_favorite_missions_on_user_id"
  end

  create_table "freelance_mission_applications", force: :cascade do |t|
    t.datetime "applied_at"
    t.datetime "client_rejected_at"
    t.datetime "client_validated_at"
    t.datetime "created_at", null: false
    t.datetime "freelancer_notified_at"
    t.bigint "freelancer_profile_id", null: false
    t.bigint "mission_id", null: false
    t.text "note"
    t.text "review_reason"
    t.bigint "reviewed_by_id"
    t.string "status", default: "applied", null: false
    t.datetime "submitted_to_client_at"
    t.datetime "updated_at", null: false
    t.index ["freelancer_profile_id"], name: "index_freelance_mission_applications_on_freelancer_profile_id"
    t.index ["mission_id", "freelancer_profile_id"], name: "index_freelance_mission_applications_uniqueness", unique: true
    t.index ["mission_id"], name: "index_freelance_mission_applications_on_mission_id"
    t.index ["reviewed_by_id"], name: "index_freelance_mission_applications_on_reviewed_by_id"
    t.index ["status"], name: "index_freelance_mission_applications_on_status"
  end

  create_table "freelance_mission_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "freelancer_profile_id", null: false
    t.bigint "mission_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "urgent", default: false, null: false
    t.index ["freelancer_profile_id", "mission_id"], name: "index_freelance_mission_preferences_on_profile_and_mission", unique: true
    t.index ["freelancer_profile_id"], name: "index_freelance_mission_preferences_on_freelancer_profile_id"
    t.index ["mission_id"], name: "index_freelance_mission_preferences_on_mission_id"
  end

  create_table "freelancer_profiles", force: :cascade do |t|
    t.integer "annual_revenue_target_eur"
    t.string "availability_status"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "freelance_legal_status"
    t.string "linkedin_url"
    t.jsonb "monthly_revenue_targets_eur", default: {}, null: false
    t.string "operational_status"
    t.jsonb "performance_snapshot", default: {}, null: false
    t.string "primary_bank_account_label"
    t.string "primary_bank_bic"
    t.string "primary_bank_iban"
    t.boolean "profile_private"
    t.bigint "region_id", null: false
    t.integer "rivyr_score_current"
    t.string "secondary_bank_account_label"
    t.string "secondary_bank_bic"
    t.string "secondary_bank_iban"
    t.bigint "specialty_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "website_url"
    t.index ["region_id"], name: "index_freelancer_profiles_on_region_id"
    t.index ["specialty_id"], name: "index_freelancer_profiles_on_specialty_id"
    t.index ["user_id"], name: "index_freelancer_profiles_on_user_id"
  end

  create_table "invoice_notes", force: :cascade do |t|
    t.boolean "action_required", default: false, null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.string "note_type", default: "follow_up", null: false
    t.datetime "resolved_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["invoice_id"], name: "index_invoice_notes_on_invoice_id"
    t.index ["user_id"], name: "index_invoice_notes_on_user_id"
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
    t.index ["placement_id", "invoice_type"], name: "index_invoices_on_placement_id_and_invoice_type", unique: true
    t.index ["placement_id"], name: "index_invoices_on_placement_id"
  end

  create_table "missions", force: :cascade do |t|
    t.text "brief_summary"
    t.bigint "client_contact_id"
    t.date "closed_at"
    t.datetime "closed_by_freelancer_at"
    t.datetime "closure_admin_read_at"
    t.text "closure_note"
    t.string "closure_reason"
    t.text "compensation_summary"
    t.boolean "contract_signed"
    t.datetime "created_at", null: false
    t.boolean "freelance_urgent", default: false, null: false
    t.bigint "freelancer_profile_id", null: false
    t.text "location"
    t.string "mission_type"
    t.date "opened_at"
    t.string "origin_type"
    t.string "pipeline_stage", default: "sourcing_candidates", null: false
    t.string "priority_level"
    t.string "reference"
    t.bigint "region_id"
    t.text "search_constraints"
    t.bigint "specialty_id"
    t.date "started_at"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["client_contact_id"], name: "index_missions_on_client_contact_id"
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

  create_table "payout_requests", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "bank_account_label"
    t.string "billing_number", null: false
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.text "note"
    t.datetime "paid_at"
    t.datetime "requested_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["invoice_id"], name: "index_payout_requests_on_invoice_id"
    t.index ["user_id"], name: "index_payout_requests_on_user_id"
  end

  create_table "placements", force: :cascade do |t|
    t.text "admin_review_note"
    t.datetime "admin_reviewed_at"
    t.bigint "admin_reviewed_by_id"
    t.integer "annual_salary_cents"
    t.boolean "candidate_accepted"
    t.bigint "candidate_id", null: false
    t.boolean "client_offer_compliant"
    t.datetime "created_at", null: false
    t.bigint "freelancer_profile_id"
    t.date "hired_at"
    t.bigint "mission_id", null: false
    t.text "notes"
    t.string "package_summary"
    t.integer "placement_fee_cents"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "workflow_status", default: "in_progress", null: false
    t.index ["admin_reviewed_by_id"], name: "index_placements_on_admin_reviewed_by_id"
    t.index ["candidate_id"], name: "index_placements_on_candidate_id"
    t.index ["freelancer_profile_id"], name: "index_placements_on_freelancer_profile_id"
    t.index ["mission_id"], name: "index_placements_on_mission_id"
    t.index ["workflow_status"], name: "index_placements_on_workflow_status"
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

  create_table "todo_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_todo_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_todo_categories_on_user_id"
  end

  create_table "todo_tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_on"
    t.string "priority", default: "medium", null: false
    t.string "status", default: "todo", null: false
    t.string "title", null: false
    t.bigint "todo_category_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["priority"], name: "index_todo_tasks_on_priority"
    t.index ["status"], name: "index_todo_tasks_on_status"
    t.index ["todo_category_id"], name: "index_todo_tasks_on_todo_category_id"
    t.index ["user_id"], name: "index_todo_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "candidate", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "work_experiences", force: :cascade do |t|
    t.bigint "candidate_id", null: false
    t.string "company"
    t.datetime "created_at", null: false
    t.integer "end_month"
    t.integer "end_year"
    t.integer "position", default: 0
    t.string "skills", default: [], array: true
    t.integer "start_month"
    t.integer "start_year"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_id"], name: "index_work_experiences_on_candidate_id"
  end

  add_foreign_key "candidate_notes", "candidates"
  add_foreign_key "candidate_notes", "users"
  add_foreign_key "candidates", "users"
  add_foreign_key "client_contacts", "clients"
  add_foreign_key "client_contacts", "users"
  add_foreign_key "client_highlights", "clients"
  add_foreign_key "client_post_comments", "client_posts"
  add_foreign_key "client_post_comments", "users"
  add_foreign_key "client_post_reactions", "client_posts"
  add_foreign_key "client_post_reactions", "users"
  add_foreign_key "client_posts", "clients"
  add_foreign_key "client_subscriptions", "clients"
  add_foreign_key "client_subscriptions", "users"
  add_foreign_key "client_values", "clients"
  add_foreign_key "commissions", "placements"
  add_foreign_key "contributions", "candidates"
  add_foreign_key "educations", "candidates"
  add_foreign_key "favorite_candidates", "candidates"
  add_foreign_key "favorite_candidates", "missions", on_delete: :cascade
  add_foreign_key "favorite_candidates", "users"
  add_foreign_key "favorite_missions", "missions"
  add_foreign_key "favorite_missions", "users"
  add_foreign_key "freelance_mission_applications", "freelancer_profiles"
  add_foreign_key "freelance_mission_applications", "missions"
  add_foreign_key "freelance_mission_applications", "users", column: "reviewed_by_id"
  add_foreign_key "freelance_mission_preferences", "freelancer_profiles"
  add_foreign_key "freelance_mission_preferences", "missions"
  add_foreign_key "freelancer_profiles", "regions"
  add_foreign_key "freelancer_profiles", "specialties"
  add_foreign_key "freelancer_profiles", "users"
  add_foreign_key "invoice_notes", "invoices"
  add_foreign_key "invoice_notes", "users"
  add_foreign_key "invoices", "placements"
  add_foreign_key "missions", "client_contacts"
  add_foreign_key "missions", "freelancer_profiles"
  add_foreign_key "missions", "regions"
  add_foreign_key "missions", "specialties"
  add_foreign_key "payments", "commissions"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payout_requests", "invoices"
  add_foreign_key "payout_requests", "users"
  add_foreign_key "placements", "candidates"
  add_foreign_key "placements", "freelancer_profiles"
  add_foreign_key "placements", "missions"
  add_foreign_key "placements", "users", column: "admin_reviewed_by_id"
  add_foreign_key "todo_categories", "users"
  add_foreign_key "todo_tasks", "todo_categories"
  add_foreign_key "todo_tasks", "users"
  add_foreign_key "work_experiences", "candidates"
end
