class UpdateInvoiceForPayee < ActiveRecord::Migration[8.0]
  def change
    # Add payee_id to invoices
    add_column :invoices, :payee_id, :integer, null: true
    add_foreign_key :invoices, :people, column: :payee_id

    # Add foreign key for client_id to reference people table instead of clients
    add_foreign_key :invoices, :people, column: :client_id

    # Add index for payee_id
    add_index :invoices, :payee_id
  end
end

