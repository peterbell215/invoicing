class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.date "date"
      t.references :client
      t.integer "amount_pence", default: 0, null: false
      t.string "amount_currency", default: "GBP", null: false
      t.integer "status", default: 0, null: false

      t.timestamps
    end
  end
end
