class CreateClientSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :client_sessions do |t|
      t.references :client
      t.references :invoice

      t.datetime "start", null: false
      t.integer "duration", null: false
      t.integer "current_rate_pence", default: 0, null: false
      t.string "current_rate_currency", default: "GBP", null: false

      t.timestamps
    end
  end
end
