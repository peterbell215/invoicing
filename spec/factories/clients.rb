FactoryBot.define do
  factory :client do
    name      { 'Test Client' }
    email     { "#{name&.parameterize(separator: ".") || 'test.client'}@example.com" }
    address1  { 'The Test Avenue' }
    town      { 'Cambridge' }
    postcode  { 'CB99 1TA' }
    active    { true }

    factory :client_with_random_name do
      name    { Faker::Name.name }
      email   { Faker::Internet.email(name: name) }
    end

    trait :with_fees do
      transient do
        gap { 1.day }
      end

      fees {
        last_fee = nil

        build_list(:fee, 3) do |fee, loop|
          fee.from = loop.zero? ? Date.new(2022, 12, 1) : last_fee.to + gap
          fee.to = loop < 2 ? fee.from + 6.months : nil
          last_fee = fee
        end
      }
    end

    trait :with_client_sessions do
      transient do
        repeats { 4 }
      end

      after(:create) do |client, context|
        create_list(:client_session, context.repeats, client: client)
      end
    end
  end
end
