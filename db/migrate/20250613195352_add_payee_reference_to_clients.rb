class AddPayeeReferenceToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :payee_reference, :string
  end
end
