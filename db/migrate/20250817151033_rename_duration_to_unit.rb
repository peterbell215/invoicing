class RenameDurationToUnit < ActiveRecord::Migration[8.0]
  def change
    add_column :client_sessions, :units, :float
    ClientSession.all.each do |client_session|
      # Convert duration (in minutes) to units (assuming 1 unit = 15 minutes)
      client_session.units = client_session.duration / 60.0
      client_session.save!
    end
    remove_column :client_sessions, :duration

    rename_column :fees, :hourly_charge_rate_currency, :unit_charge_rate_currency
    rename_column :fees, :hourly_charge_rate_pence, :unit_charge_rate_pence
  end
end
