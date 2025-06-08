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

ActiveRecord::Schema[8.0].define(version: 2025_06_08_172315) do
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
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "client_sessions", force: :cascade do |t|
    t.integer "client_id"
    t.integer "invoice_id"
    t.integer "duration", null: false
    t.integer "hourly_session_rate_pence", default: 0, null: false
    t.string "hourly_session_rate_currency", default: "GBP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.date "session_date", null: false
    t.index ["client_id"], name: "index_client_sessions_on_client_id"
    t.index ["invoice_id"], name: "index_client_sessions_on_invoice_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "address1", null: false
    t.string "address2"
    t.string "town", null: false
    t.string "postcode", null: false
    t.string "phone"
    t.integer "paid_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.index ["email"], name: "index_clients_on_email", unique: true
    t.index ["paid_by_id"], name: "index_clients_on_paid_by_id"
  end

  create_table "fees", force: :cascade do |t|
    t.integer "client_id"
    t.date "from"
    t.date "to"
    t.integer "hourly_charge_rate_pence", default: 0, null: false
    t.string "hourly_charge_rate_currency", default: "GBP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_fees_on_client_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.date "date"
    t.integer "client_id"
    t.integer "amount_pence", default: 0, null: false
    t.string "amount_currency", default: "GBP", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "payee_id"
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["payee_id"], name: "index_invoices_on_payee_id"
  end

  create_table "payees", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "address1", null: false
    t.string "address2"
    t.string "town", null: false
    t.string "postcode", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "organisation", null: false
    t.boolean "active", default: true
    t.index ["email"], name: "index_payees_on_email", unique: true
    t.index ["organisation"], name: "index_payees_on_organisation", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "client_sessions", "clients"
  add_foreign_key "clients", "payees", column: "paid_by_id"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "payees"
end
