class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string "name"
      t.string "address1"
      t.string "address2"
      t.string "town"
      t.string "postcode"
      t.string "email"
      t.string "title"

      t.timestamps
    end

    add_index :clients, :email, unique: true
  end
end
