class ClientSessionRenameHourlySessionRateToUnitSessionRate < ActiveRecord::Migration[8.0]
  def change
    rename_column :client_sessions, :hourly_session_rate_pence, :unit_session_rate_pence
    rename_column :client_sessions, :hourly_session_rate_currency, :unit_session_rate_currency
  end
end
