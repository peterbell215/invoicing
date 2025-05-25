FactoryBot.define do
  factory :client_session do
    start                { DateTime.new(2024, 2, 1, 9, 0) }
    duration             { 60 }
    hourly_session_rate  { Money.new(6000, 'GBP') }
  end
end
