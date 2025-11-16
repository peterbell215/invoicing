FactoryBot.define do
  factory :credit_note do
    transient do
      payee { nil}
      invoice_param { nil }
    end

    # Don't create client or invoice by default - let tests provide them
    client { invoice_param&.client }
    invoice { invoice_param }

    amount { Money.new(-2500, "GBP") } # -£25.00
    reason { "Test credit note reason" }
    date { Date.current }
    status { :created }

    after(:build) do |credit_note, evaluator|
      credit_note.payee = evaluator.payee if evaluator.payee
    end
  end
end

