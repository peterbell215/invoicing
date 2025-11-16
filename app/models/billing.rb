# Base class for billing documents (Invoices and Credit Notes)
class Billing < ApplicationRecord
  belongs_to :client
  belongs_to :payee, class_name: "Payee", optional: true
  has_one_attached :pdf
  has_rich_text :text

  monetize :amount_pence

  validates :date, presence: true

  after_initialize :set_default_date, if: :new_record?

  # Returns the entity (Client or Payee) who should receive the billing document
  def bill_to
    payee || client
  end

  # Returns true if this billing document is billed to the client directly
  def self_paid?
    payee.nil?
  end

  private

  # Sets the default date for new billing records
  def set_default_date
    self.date ||= Date.current
  end
end

