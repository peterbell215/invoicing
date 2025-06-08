class FixClient < ActiveRecord::Migration[8.0]
  def change
    remove_column :clients, :county
  end
end
