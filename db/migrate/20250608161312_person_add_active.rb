class PersonAddActive < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :active, :boolean, default: true
    add_column :payees, :active, :boolean, default: true
  end
end
