FactoryBot.define do
  factory :payee do
    name { "The Bursar" }
    organisation { "The College" }
    email { "bursar@college.edu" }
    address1 { "Financial Office" }
    address2 { "College Campus" }
    town { "Cambridge" }
    postcode { "CB2 1TN" }
    phone { "01223 123456" }
    active { true }
  end
end

