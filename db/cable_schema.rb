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

ActiveRecord::Schema[8.1].define(version: 2026_04_10_024228) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.integer "recipient_count"
    t.string "recipient_scope", default: "all_members", null: false
    t.datetime "sent_at"
    t.string "slug"
    t.string "subject", null: false
    t.bigint "target_event_id"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_announcements_on_author_id"
    t.index ["club_id", "sent_at"], name: "index_announcements_on_club_id_and_sent_at"
    t.index ["club_id", "slug"], name: "index_announcements_on_club_id_and_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["club_id"], name: "index_announcements_on_club_id"
    t.index ["target_event_id"], name: "index_announcements_on_target_event_id"
  end

  create_table "clubs", force: :cascade do |t|
    t.string "ca_registry_number"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.string "custom_domain"
    t.string "ein"
    t.string "font_choice", default: "Inter"
    t.string "legal_name"
    t.string "name", null: false
    t.string "primary_color", default: "#c8a96e"
    t.string "slug", null: false
    t.string "smtp_from"
    t.string "smtp_host"
    t.text "smtp_pass"
    t.string "smtp_port", default: "587"
    t.string "smtp_user"
    t.string "ssl_status", default: "pending"
    t.text "stripe_publishable_key"
    t.text "stripe_secret_key"
    t.text "stripe_webhook_secret"
    t.datetime "updated_at", null: false
    t.index ["custom_domain"], name: "index_clubs_on_custom_domain", unique: true, where: "(custom_domain IS NOT NULL)"
    t.index ["slug"], name: "index_clubs_on_slug", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.integer "capacity", null: false
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "name", null: false
    t.integer "price_cents", default: 0, null: false
    t.datetime "refund_cutoff_at"
    t.string "slug"
    t.datetime "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.string "venue", null: false
    t.index ["club_id", "slug"], name: "index_events_on_club_id_and_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["club_id", "starts_at"], name: "index_events_on_club_id_and_starts_at"
    t.index ["club_id", "status"], name: "index_events_on_club_id_and_status"
    t.index ["club_id"], name: "index_events_on_club_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "magic_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "member_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["member_id"], name: "index_magic_links_on_member_id"
    t.index ["token"], name: "index_magic_links_on_token", unique: true
  end

  create_table "members", force: :cascade do |t|
    t.string "bio"
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "google_uid"
    t.string "name", null: false
    t.string "password_digest"
    t.string "role", default: "member", null: false
    t.text "signup_message"
    t.string "slug"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.datetime "verification_sent_at"
    t.string "verification_token"
    t.datetime "verified_at"
    t.index ["club_id", "email"], name: "index_members_on_club_id_and_email", unique: true
    t.index ["club_id", "google_uid"], name: "index_members_on_club_id_and_google_uid", unique: true, where: "(google_uid IS NOT NULL)"
    t.index ["club_id", "slug"], name: "index_members_on_club_id_and_slug", unique: true, where: "(slug IS NOT NULL)"
    t.index ["club_id"], name: "index_members_on_club_id"
    t.index ["verification_token"], name: "index_members_on_verification_token", unique: true, where: "(verification_token IS NOT NULL)"
  end

  create_table "rsvps", force: :cascade do |t|
    t.integer "amount_paid_cents"
    t.datetime "cancelled_at"
    t.string "checkout_session_id"
    t.datetime "created_at", null: false
    t.integer "donation_amount_cents", default: 0
    t.bigint "event_id", null: false
    t.bigint "member_id", null: false
    t.datetime "paid_at"
    t.datetime "receipt_sent_at"
    t.string "refund_status"
    t.datetime "refunded_at"
    t.string "status", default: "confirmed", null: false
    t.string "stripe_charge_id"
    t.string "stripe_refund_id"
    t.datetime "updated_at", null: false
    t.index ["checkout_session_id"], name: "index_rsvps_on_checkout_session_id", unique: true, where: "(checkout_session_id IS NOT NULL)"
    t.index ["event_id", "member_id"], name: "index_rsvps_on_event_id_and_member_id", unique: true
    t.index ["event_id", "status"], name: "index_rsvps_on_event_id_and_status"
    t.index ["event_id"], name: "index_rsvps_on_event_id"
    t.index ["member_id"], name: "index_rsvps_on_member_id"
    t.index ["stripe_charge_id"], name: "index_rsvps_on_stripe_charge_id", where: "(stripe_charge_id IS NOT NULL)"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.bigint "member_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["member_id"], name: "index_sessions_on_member_id"
    t.index ["token"], name: "index_sessions_on_token", unique: true
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "clubs"
  add_foreign_key "announcements", "events", column: "target_event_id"
  add_foreign_key "announcements", "members", column: "author_id"
  add_foreign_key "events", "clubs"
  add_foreign_key "magic_links", "members"
  add_foreign_key "members", "clubs"
  add_foreign_key "rsvps", "events"
  add_foreign_key "rsvps", "members"
  add_foreign_key "sessions", "members"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
