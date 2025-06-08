# Hold details of an invoice.
class Invoice < ApplicationRecord
  belongs_to :client
  belongs_to :payee, class_name: 'Payee', optional: true
  has_many :client_sessions, dependent: :nullify
  has_one_attached :pdf

  monetize :amount_pence

  validates :date, presence: true
  validate :validate_editable_status, on: :update
  before_validation :set_payee_from_client, on: :create

  enum :status, { created: 0, sent: 1, paid: 2 }

  # Returns the entity (Client or Payee) who should receive the invoice
  def bill_to
    payee || client
  end

  # Returns true if this invoice is billed to the client directly
  def self_paid?
    payee.nil?
  end

  private

  def validate_editable_status
    if status_changed? && status_was != 'created'
      errors.add(:base, "Cannot modify an invoice that has been sent or paid")
    end
  end

  # Set the payee based on the client's payment arrangement
  def set_payee_from_client
    self.payee ||= client.paid_by if client&.paid_by.present?
  end
end
