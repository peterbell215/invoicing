class AddActiveToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :active, :boolean
  end
end
