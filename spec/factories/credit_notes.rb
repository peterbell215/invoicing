FactoryBot.define do
  factory :credit_note do
    transient do
      invoice_param { nil }
    end
    
    # Invoice is required - let tests provide it
    invoice { invoice_param }

    amount { Money.new(-2500, "GBP") } # -£25.00
    reason { "Test credit note reason" }
    date   { Date.current }
    status { :created }
  end
end

