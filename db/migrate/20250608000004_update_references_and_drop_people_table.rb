class UpdateReferencesAndDropPeopleTable < ActiveRecord::Migration[7.0]
  def up
    # Update foreign keys in other tables

    # Update fees to point to the clients table
    # First, ensure the column exists on the fees table
    unless column_exists?(:fees, :client_id)
      add_reference :fees, :client, foreign_key: true
    end

    # Update invoices table if it references people/clients/payees
    if column_exists?(:invoices, :client_id)
      # The column already exists, we just need to ensure it points to the right table
      remove_foreign_key :invoices, :people if foreign_key_exists?(:invoices, :people)
      add_foreign_key :invoices, :clients if !foreign_key_exists?(:invoices, :clients)
    end

    if column_exists?(:invoices, :payee_id)
      # The column already exists, we just need to ensure it points to the right table
      remove_foreign_key :invoices, :people if foreign_key_exists?(:invoices, :people)
      add_foreign_key :invoices, :payees if !foreign_key_exists?(:invoices, :payees)
    end

    # Update client_sessions table if it references people/clients
    if column_exists?(:client_sessions, :client_id)
      # The column already exists, we just need to ensure it points to the right table
      remove_foreign_key :client_sessions, :people if foreign_key_exists?(:client_sessions, :people)
      add_foreign_key :client_sessions, :clients if !foreign_key_exists?(:client_sessions, :clients)
    end

    # Finally, drop the people table
    drop_table :people
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot reverse this migration as it would require recreating the people table"
  end
end
