FactoryBot.define do
  factory :invoice do
    date { Date.new(2024, 3, 16) }

    client          { Client.find_by_name("Test Client") || FactoryBot.create(:client) }

    after(:create) do |invoice|
      create_list(:client_session, 3, client: invoice.client, invoice: invoice)
    end
  end
end
