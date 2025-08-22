# Represents an individual session with a specific client.
class ClientSession < ApplicationRecord
  belongs_to :client
  belongs_to :invoice, optional: true

  monetize :unit_session_rate_pence

  validates :session_date, presence: true
  validates :units, presence: true, numericality: { greater_than: 0 }
  validates :unit_session_rate, presence: true

  before_destroy :check_destroyable
  before_update :check_updatable
  after_update :update_invoice_amount, if: :amount_affecting_change?
  after_save :update_invoice_amount, if: :amount_affecting_change?

  def summary
    "#{self.client.name} on #{self.session_date.strftime('%d %b %Y')}"
  end

  def fee
    return Money.new(0) unless units && unit_session_rate
    unit_session_rate * units
  end

  def destroyable?
    return true if invoice.nil?
    invoice.created?
  end

  def updatable?
    return true if invoice.nil?
    invoice.created?
  end

  private

  def check_destroyable
    unless destroyable?
      errors.add(:base, "Cannot delete once invoice sent or paid")
      throw :abort
    end
  end

  def check_updatable
    unless updatable?
      errors.add(:base, "Cannot update once invoice sent or paid")
      throw :abort
    end
  end

  def amount_affecting_change?
    return false unless invoice.present? && invoice.created?
    saved_change_to_units? || saved_change_to_unit_session_rate_pence?
  end

  def update_invoice_amount
    return unless invoice.present? && invoice.created?
    invoice.save! # This will trigger the invoice's before_save callback to update_amount
  end
end
