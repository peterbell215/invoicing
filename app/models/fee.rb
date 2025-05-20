# This model represents the default charge that is applied to a specific client over a specific period.
class Fee < ApplicationRecord
  belongs_to :client

  monetize :hourly_charge_rate_pence

  # Checks if for the provided client_id any fee entries' date ranges overlap.
  # @param [ActiveResult] fees
  # @return [FeeHistory]
  def self.overlap?(fees)
    return false if fees.length <= 1

    overlapping_pair = fees.each_cons(2).find { |previous, following| previous.to >= following.from }
    overlapping_pair&.first
  end

  def json_with_dinero
    self.as_json(methods: [:hourly_charge_rate_as_dinero],
                 except: %i[hourly_charge_rate_pence hourly_charge_rate_currency])
  end

  # Provides a method to generate a hash with the fields needed to instantiate as a Dinero object in JS.
  # @return [Hash]
  delegate :as_dinero, to: :hourly_charge_rate, prefix: true
end
