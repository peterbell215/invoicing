FactoryBot.define do
  factory :message do
    text { "This is a test message content" }
    from_date { Date.current }
    until_date { Date.current + 30.days }

    trait :for_all_clients do
      after(:build) do |message|
        message.all_clients = true
      end
    end

    trait :for_specific_clients do
      after(:create) do |message|
        create_list(:client, 2).each do |client|
          message.apply_to_client(client)
        end
      end
    end

    trait :without_dates do
      from_date { nil }
      until_date { nil }
    end
  end
end
