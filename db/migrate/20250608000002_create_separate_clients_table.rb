class CreateSeparateClientsTable < ActiveRecord::Migration[7.0]
  def change
    # Create a new clients table
    create_table :clients do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :address1, null: false
      t.string :address2
      t.string :town, null: false
      t.string :county
      t.string :postcode, null: false
      t.string :phone
      t.references :paid_by, foreign_key: { to_table: :payees }, null: true

      t.timestamps
    end

    add_index :clients, :email, unique: true
  end
end

