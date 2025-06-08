class RenamingClientToPersonForSTI < ActiveRecord::Migration[8.0]
  def change
    # Rename the clients table to people
    rename_table :clients, :people

    # Add type column for Single Table Inheritance
    add_column :people, :type, :string

    # Add paid_by_id self-reference column
    add_column :people, :paid_by_id, :integer, null: true
    add_foreign_key :people, :people, column: :paid_by_id

    # Set all existing records to be of type 'Client'
    reversible do |dir|
      dir.up do
        execute("UPDATE people SET type = 'Client'")
      end
    end

    # Add an index on type for better query performance
    add_index :people, :type
    add_index :people, :paid_by_id
  end
end

