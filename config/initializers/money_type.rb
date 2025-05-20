require "money"

# Custom Money type for ActiveModel::Type
class MoneyType < ActiveRecord::Type::Value
  def type
    :money
  end

  def money?
    true
  end

  def cast(value)
    return value if value.is_a?(Money)
    return nil if value.nil?

    case value
    when String
      Money.from_amount(value.to_f)
    when Numeric
      Money.new(value * 100)
    else
      value
    end
  end

  def serialize(value)
    value
  end
end

Rails.application.config.to_prepare do
  ActiveRecord::Type.register(:money, MoneyType)
end
