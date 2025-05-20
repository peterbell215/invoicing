class CreateFees < ActiveRecord::Migration[8.0]
  def change
    create_table :fees do |t|
      t.references :client
      t.date "from"
      t.date "to"
      t.integer "hourly_charge_rate_pence", default: 0, null: false
      t.string "hourly_charge_rate_currency", default: "GBP", null: false

      t.timestamps
    end
  end
end
