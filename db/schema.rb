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

ActiveRecord::Schema[8.0].define(version: 2025_05_25_000001) do
  create_table "client_sessions", force: :cascade do |t|
    t.integer "client_id"
    t.integer "invoice_id"
    t.datetime "start", null: false
    t.integer "duration", null: false
    t.integer "hourly_session_rate_pence", default: 0, null: false
    t.string "hourly_session_rate_currency", default: "GBP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_sessions_on_client_id"
    t.index ["invoice_id"], name: "index_client_sessions_on_invoice_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "address1"
    t.string "address2"
    t.string "town"
    t.string "postcode"
    t.string "email"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active"
    t.index ["email"], name: "index_clients_on_email", unique: true
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
    t.index ["client_id"], name: "index_invoices_on_client_id"
  end
end
