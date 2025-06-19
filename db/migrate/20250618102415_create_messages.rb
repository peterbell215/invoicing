class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.date :from
      t.date :until

      t.timestamps
    end
  end
end
