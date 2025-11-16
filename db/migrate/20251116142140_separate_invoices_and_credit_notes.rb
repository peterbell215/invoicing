class SeparateInvoicesAndCreditNotes < ActiveRecord::Migration[8.1]
  def up
    # Create new credit_notes table - client and payee accessed through invoice
    create_table :credit_notes do |t|
      t.integer :invoice_id, null: false
      t.date :date, null: false
      t.integer :amount_pence, default: 0, null: false
      t.string :amount_currency, default: "GBP", null: false
      t.text :reason, null: false
      t.integer :status, default: 0, null: false
      t.timestamps
    end

    # Add index
    add_index :credit_notes, :invoice_id

    # Copy credit notes from billings table to new credit_notes table (if any exist)
    if ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM billings WHERE type = 'CreditNote'").to_i > 0
      execute <<-SQL
        INSERT INTO credit_notes (id, invoice_id, date, amount_pence, amount_currency, reason, status, created_at, updated_at)
        SELECT id, invoice_id, date, amount_pence, amount_currency, reason, status, created_at, updated_at
        FROM billings
        WHERE type = 'CreditNote'
      SQL

      # Remove credit notes from billings table
      execute "DELETE FROM billings WHERE type = 'CreditNote'"
    end

    # Rename billings table back to invoices
    rename_table :billings, :invoices

    # Add foreign key after renaming
    add_foreign_key :credit_notes, :invoices, column: :invoice_id

    # Remove STI and credit note specific columns from invoices
    remove_column :invoices, :type
    remove_column :invoices, :invoice_id
    remove_column :invoices, :reason
  end

  def down
    # Rename invoices back to billings
    rename_table :invoices, :billings

    # Add back STI and credit note columns
    add_column :billings, :type, :string
    add_column :billings, :invoice_id, :integer
    add_column :billings, :reason, :text
    add_index :billings, :type
    add_index :billings, :invoice_id

    # Set type for existing invoices
    execute "UPDATE billings SET type = 'Invoice' WHERE type IS NULL"

    # Copy credit notes back to billings table (if any exist)
    if ActiveRecord::Base.connection.table_exists?('credit_notes') &&
       ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM credit_notes").to_i > 0

      # Need to get client_id and payee_id from the invoice
      execute <<-SQL
        INSERT INTO billings (id, invoice_id, client_id, payee_id, date, amount_pence, amount_currency, reason, status, type, created_at, updated_at)
        SELECT cn.id, cn.invoice_id, b.client_id, b.payee_id, cn.date, cn.amount_pence, cn.amount_currency, cn.reason, cn.status, 'CreditNote', cn.created_at, cn.updated_at
        FROM credit_notes cn
        INNER JOIN billings b ON cn.invoice_id = b.id
      SQL
    end

    # Drop credit_notes table
    drop_table :credit_notes
  end
end
