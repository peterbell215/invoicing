FactoryBot.define do
  factory :client_session do
    client                      { Client.find_by_name("Test Client") || FactoryBot.create(:client) }
    sequence(:session_date)     { |n| Date.new(2025, 1, 10) + (n-1).weeks }
    units                       { 1.0 }
    unit_session_rate           { Money.new(6000, 'GBP') }
  end
end
