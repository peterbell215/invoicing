# Represents an individual session with a specific client.
class ClientSession < ApplicationRecord
  belongs_to :client
  belongs_to :invoice, optional: true

  monetize :current_rate_pence

  validates :start, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }

  before_validation :set_current_rate, on: :create
  before_validation :set_default_duration, on: :create

  before_destroy :dont_if_invoice_sent

  def destroyable?
    self.invoice.nil? || self.invoice.status == 'created'
  end

  private

  def set_current_rate
    return unless client && client.current_rate
    self.current_rate = client.current_rate
  end

  def set_default_duration
    self.duration ||= 50
  end

  def dont_if_invoice_sent
    return if self.destroyable?

    raise ActiveRecord::RecordNotDestroyed, 'Cannot delete once invoice sent or paid'
  end
end
