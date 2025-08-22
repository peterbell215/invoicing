FactoryBot.define do
  factory :invoice do
    date     { Date.new(2025, 2, 1) }

    client   { Client.find_by_name("Test Client") || FactoryBot.create(:client) }

    factory :invoice_with_client_sessions do
      transient do
        client_sessions_count { 3 }
      end

      client_sessions do
        Array.new(client_sessions_count) { association(:client_session, client: client) }
      end
    end
  end
end
