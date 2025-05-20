# Represents an individual session with a specific client.
class ClientSession < ApplicationRecord
  belongs_to :client
  belongs_to :invoice, optional: true

  monetize :current_rate_pence

  before_destroy :dont_if_invoice_sent

  def destroyable?
    self.invoice.nil? || self.invoice.status == 'created'
  end

  private

  def dont_if_invoice_sent
    return if self.destroyable?

    raise ActiveRecord::RecordNotDestroyed, 'Cannot delete once invoice sent or paid'
  end
end
