class RenameCurrentRateInClientSessions < ActiveRecord::Migration[8.0]
  def change
    rename_column :client_sessions, :current_rate_pence, :hourly_session_rate_pence
    rename_column :client_sessions, :current_rate_currency, :hourly_session_rate_currency
  end
end

