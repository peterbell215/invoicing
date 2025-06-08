# frozen_string_literal: true

# Person concern module for shared behavior between Client and Payee
module Person
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :address1, presence: true
    validates :town, presence: true
    validates :postcode, format: { with: /\A[a-z]{1,2}\d[a-z\d]?\s*\d[a-z]{2}\z/i, message: 'is badly formed postcode' }
  end

  # Common methods for both Client and Payee
  def address_multi_line
    [address1, address2, "#{town}, #{county} #{postcode}"].reject(&:blank?).join("\n")
  end

  def address_single_line
    [address1, address2, town, county, postcode].reject(&:blank?).join(", ")
  end
end
