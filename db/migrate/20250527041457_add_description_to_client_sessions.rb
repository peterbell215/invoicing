class AddDescriptionToClientSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :client_sessions, :description, :text
  end
end
