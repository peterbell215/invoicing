FactoryBot.define do
  factory :payee do
    sequence(:name) { |n| "Testpayee #{n.to_words.capitalize }" }
    organisation    { "The College" }
    email           { "#{name&.parameterize(separator: ".") || 'test.client'}@example.com" }
    address1        { "Financial Office" }
    address2        { "College Campus" }
    town            { "Cambridge" }
    postcode        { "CB2 1TN" }
    phone           { "01223 123456" }
    active          { true }
  end
end

