# Represents an individual session with a specific client.
class ClientSession < ApplicationRecord
  belongs_to :client
  belongs_to :invoice, optional: true

  monetize :hourly_session_rate_pence

  validates :session_date, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }

  before_validation :set_hourly_session_rate, on: :create
  after_initialize :set_default_duration

  before_destroy :dont_if_invoice_sent

  def destroyable?
    self.invoice.nil? || self.invoice.status == "created"
  end

  def fee
    self.hourly_session_rate * (self.duration/60.0)
  end

  # Return the entity (Client or Payee) who should be billed for this session
  def billable_to
    client.effective_payee
  end

  private

  def set_hourly_session_rate
    return unless client&.current_rate
    self.hourly_session_rate = client.current_rate
  end

  def set_default_duration
    self.duration ||= 50
  end

  def dont_if_invoice_sent
    return if self.destroyable?

    raise ActiveRecord::RecordNotDestroyed, "Cannot delete once invoice sent or paid"
  end
end
