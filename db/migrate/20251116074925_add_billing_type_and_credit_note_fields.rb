class AddBillingTypeAndCreditNoteFields < ActiveRecord::Migration[8.1]
  def change
    # Add type column for Single Table Inheritance
    add_column :invoices, :type, :string
    add_index :invoices, :type
    
    # Set existing records to 'Invoice' type
    reversible do |dir|
      dir.up do
        execute "UPDATE invoices SET type = 'Invoice'"
      end
    end
    
    # Add credit note specific fields
    add_column :invoices, :invoice_id, :integer
    add_column :invoices, :reason, :text
    
    # Add index for invoice_id (for credit notes)
    add_index :invoices, :invoice_id
    
    # Rename table to billings
    rename_table :invoices, :billings
  end
end

