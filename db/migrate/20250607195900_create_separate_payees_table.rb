class CreateSeparatePayeesTable < ActiveRecord::Migration[7.0]
  def change
    create_table :payees do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :address1, null: false
      t.string :address2
      t.string :town, null: false
      t.string :county
      t.string :postcode, null: false
      t.string :phone
      t.string :account_name
      t.string :account_number
      t.string :sort_code
      t.string :vat_number

      t.timestamps
    end

    add_index :payees, :email, unique: true
  end
end

