class FixPayee < ActiveRecord::Migration[8.0]
  def change
    add_column :payees, :organisation, :string

    remove_column :payees, :county
    remove_column :payees, :account_name
    remove_column :payees, :account_number
    remove_column :payees, :sort_code
    remove_column :payees, :vat_number

    add_index :payees, :organisation, unique: true
  end
end
