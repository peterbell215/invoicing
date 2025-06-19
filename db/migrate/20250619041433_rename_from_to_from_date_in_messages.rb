class RenameFromToFromDateInMessages < ActiveRecord::Migration[8.0]
  def change
    rename_column :messages, :from, :from_date
  end
end
