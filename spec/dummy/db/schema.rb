# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_11_30_162719) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "audits", id: :serial, force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_id", "associated_type"], name: "associated_index"
    t.index ["auditable_id", "auditable_type"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "companies", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "phone_number", limit: 255, null: false
    t.string "website", limit: 255, null: false
    t.string "email", limit: 255, null: false
    t.string "address_1", limit: 255, null: false
    t.string "address_2", limit: 255
    t.string "city", limit: 255, null: false
    t.string "state", limit: 255, null: false
    t.string "zipcode", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "validity_checked_at"
    t.text "valid_user_domains", default: [], array: true
    t.string "timezone", null: false
  end

  create_table "divisions", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.integer "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "division_status"
    t.boolean "notify", default: false, null: false
    t.string "timezone"
    t.decimal "hourly_rate", precision: 8, scale: 2, default: "0.0", null: false
    t.index ["name"], name: "index_divisions_on_name", unique: true, where: "(division_status = 0)"
    t.index ["owner_id"], name: "index_divisions_on_owner_id"
  end

  create_table "notification_security_roles", force: :cascade do |t|
    t.integer "security_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notification_type_id", null: false
    t.index ["notification_type_id", "security_role_id"], name: "unique_notification_roles", unique: true
  end

  create_table "notification_settings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notification_type_id", null: false
    t.index ["notification_type_id", "user_id"], name: "index_notification_settings_on_notification_type_id_and_user_id", unique: true
  end

  create_table "notification_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "auth_mode", default: 0, null: false
    t.index ["name"], name: "index_notification_types_on_name", unique: true
  end

  create_table "security_roles", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.boolean "admin", default: false, null: false
    t.boolean "read_user", default: false, null: false
    t.boolean "read_audit", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "create_division", default: false, null: false
    t.boolean "read_division", default: false, null: false
    t.boolean "update_division", default: false, null: false
    t.boolean "delete_division", default: false, null: false
    t.index ["name"], name: "index_security_roles_on_name", unique: true
  end

  create_table "security_roles_users", id: :serial, force: :cascade do |t|
    t.integer "security_role_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["security_role_id", "user_id"], name: "index_security_roles_users_on_security_role_id_and_user_id", unique: true
    t.index ["security_role_id"], name: "index_security_roles_users_on_security_role_id"
    t.index ["user_id"], name: "index_security_roles_users_on_user_id"
  end

  create_table "statuses", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_statuses_on_name", unique: true
  end

  create_table "system_messages", force: :cascade do |t|
    t.text "message", null: false
    t.integer "user_id", null: false
    t.integer "send_to", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "message_type", null: false
    t.index ["user_id"], name: "index_system_messages_on_user_id"
  end

  create_table "user_statuses", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: false, null: false
    t.boolean "validate_email", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_user_statuses_on_name", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 255
    t.string "first_name", limit: 255, null: false
    t.string "last_name", limit: 255, null: false
    t.string "mobile_phone", limit: 255
    t.string "timezone", limit: 255, null: false
    t.string "global_search_default", limit: 255
    t.integer "user_status_id", null: false
    t.string "authy_id"
    t.datetime "last_sign_in_with_authy"
    t.boolean "authy_enabled", default: false, null: false
    t.string "firebase_id"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "external", default: false, null: false
    t.index ["authy_id"], name: "index_users_on_authy_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["first_name"], name: "index_users_on_first_name"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["last_name"], name: "index_users_on_last_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_status_id"], name: "index_users_on_user_status_id"
  end

  add_foreign_key "audits", "users"
  add_foreign_key "divisions", "users", column: "owner_id"
  add_foreign_key "notification_security_roles", "notification_types"
  add_foreign_key "notification_security_roles", "security_roles"
  add_foreign_key "notification_settings", "notification_types"
  add_foreign_key "notification_settings", "users"
  add_foreign_key "security_roles_users", "security_roles"
  add_foreign_key "security_roles_users", "users"
  add_foreign_key "system_messages", "users"
  add_foreign_key "users", "user_statuses"
  add_foreign_key "users", "users", column: "invited_by_id"
end
