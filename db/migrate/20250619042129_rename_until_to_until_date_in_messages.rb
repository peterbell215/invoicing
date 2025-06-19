class RenameUntilToUntilDateInMessages < ActiveRecord::Migration[8.0]
  def change
    rename_column :messages, :until, :until_date
  end
end
