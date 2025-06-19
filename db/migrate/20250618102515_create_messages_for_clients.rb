class CreateMessagesForClients < ActiveRecord::Migration[8.0]
  def change
    create_table :messages_for_clients do |t|
      t.references :message, null: false, foreign_key: true
      t.references :client, null: true, foreign_key: true

      t.timestamps
    end
  end
end
