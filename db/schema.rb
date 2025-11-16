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

ActiveRecord::Schema[8.1].define(version: 2025_11_16_142140) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "client_sessions", force: :cascade do |t|
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "invoice_id"
    t.date "session_date", null: false
    t.string "unit_session_rate_currency", default: "GBP", null: false
    t.integer "unit_session_rate_pence", default: 0, null: false
    t.float "units"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_sessions_on_client_id"
    t.index ["invoice_id"], name: "index_client_sessions_on_invoice_id"
  end

  create_table "clients", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "address1", null: false
    t.string "address2"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.integer "paid_by_id"
    t.string "payee_reference"
    t.string "phone"
    t.string "postcode", null: false
    t.string "town", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_clients_on_email", unique: true
    t.index ["paid_by_id"], name: "index_clients_on_paid_by_id"
  end

  create_table "credit_notes", force: :cascade do |t|
    t.string "amount_currency", default: "GBP", null: false
    t.integer "amount_pence", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "invoice_id", null: false
    t.text "reason", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_credit_notes_on_invoice_id"
  end

  create_table "fees", force: :cascade do |t|
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.date "from"
    t.date "to"
    t.string "unit_charge_rate_currency", default: "GBP", null: false
    t.integer "unit_charge_rate_pence", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_fees_on_client_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "amount_currency", default: "GBP", null: false
    t.integer "amount_pence", default: 0, null: false
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "payee_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["payee_id"], name: "index_invoices_on_payee_id"
  end

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "from_date"
    t.date "until_date"
    t.datetime "updated_at", null: false
  end

  create_table "messages_for_clients", force: :cascade do |t|
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_messages_for_clients_on_client_id"
    t.index ["message_id"], name: "index_messages_for_clients_on_message_id"
  end

  create_table "payees", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "address1", null: false
    t.string "address2"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "organisation", null: false
    t.string "phone"
    t.string "postcode", null: false
    t.string "town", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_payees_on_email", unique: true
    t.index ["organisation"], name: "index_payees_on_organisation"
  end

  create_table "users", force: :cascade do |t|
    t.string "confirmation_token", limit: 128
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", limit: 128, null: false
    t.string "remember_token", limit: 128, null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "client_sessions", "clients"
  add_foreign_key "clients", "payees", column: "paid_by_id"
  add_foreign_key "credit_notes", "invoices"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "payees"
  add_foreign_key "messages_for_clients", "clients"
  add_foreign_key "messages_for_clients", "messages"
end
