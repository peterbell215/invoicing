class MigrateDataToNewTables < ActiveRecord::Migration[7.0]
  def up
    # First, create any payees (since clients may reference them)
    execute <<-SQL
      INSERT INTO payees (
        name, email, address1, address2, town, postcode, created_at, updated_at
      )
      SELECT 
        name, email, address1, address2, town, postcode, created_at, updated_at
      FROM people
      WHERE type = 'Payee'
    SQL

    # Then create clients
    execute <<-SQL
      INSERT INTO payees (
        name, email, address1, address2, town, postcode, created_at, updated_at
      )
      SELECT 
        name, email, address1, address2, town, postcode, created_at, updated_at
      FROM people
      WHERE type = 'Client'
    SQL
  end

  def down
    # We could try to move data back to the people table, but that might be complex
    # and risky. Let's just raise an error instead.
    raise ActiveRecord::IrreversibleMigration
  end
end
