class ChangeStartToSessionDateInClientSessions < ActiveRecord::Migration[8.0]
  def up
    # First add the new column
    add_column :client_sessions, :session_date, :date

    ClientSession.all.each do |client_session|
      start_as_date = client_session.start.to_date
      client_session.session_date = start_as_date
      client_session.save!
    end

    # Make session_date not nullable
    change_column_null :client_sessions, :session_date, false

    # Remove the old column
    remove_column :client_sessions, :start
  end
end
