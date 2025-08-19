# Represents an individual session with a specific client.
class ClientSession < ApplicationRecord
  belongs_to :client
  belongs_to :invoice, optional: true

  monetize :unit_session_rate_pence

  validates :session_date, presence: true
  validates :units, presence: true, numericality: { greater_than: 0 }

  before_validation :set_unit_session_rate, on: :create
  after_initialize :set_default_units

  before_update :dont_if_invoice_sent
  before_destroy :dont_if_invoice_sent

  def destroyable?
    self.invoice.nil? || self.invoice.status == "created"
  end

  def fee
    self.unit_session_rate * self.units
  end

  def summary
    "#{self.client.name} on #{self.session_date.strftime('%d %b %Y')}"
  end

  # Return the entity (Client or Payee) who should be billed for this session
  def billable_to
    client.effective_payee
  end

  private

  def set_unit_session_rate
    return unless client&.current_rate
    self.unit_session_rate = client.current_rate
  end

  def set_default_units
    self.units ||= 1.0
  end

  def dont_if_invoice_sent
    return if self.destroyable?

    raise ActiveRecord::RecordNotDestroyed, "Cannot delete once invoice sent or paid"
  end
end
