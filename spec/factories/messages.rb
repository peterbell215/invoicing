FactoryBot.define do
  factory :message do
    text { nil }
    from_date { "2025-06-18" }
    until_date { "2025-06-18" }

    factory :message_for_all_clients, parent: :message do
      all_clients { true }
    end
  end


end
