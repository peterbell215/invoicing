# Represents a credit note issued against an invoice
class CreditNote < ApplicationRecord
  belongs_to :invoice, class_name: 'Invoice'
  has_one_attached :pdf
  has_rich_text :text

  # Delegate client and payee to invoice
  delegate :client, to: :invoice
  delegate :payee, to: :invoice, allow_nil: true

  monetize :amount_pence

  validates :date, presence: true
  validates :invoice_id, presence: true
  validates :reason, presence: true
  validates :amount_pence, presence: true, numericality: { other_than: 0, message: "cannot be zero" }
  validate :amount_cannot_exceed_invoice_amount
  validate :invoice_must_be_sent_or_paid
  validate :validate_editable_status, on: :update

  enum :status, { created: 0, sent: 1 }

  before_validation :ensure_negative_amount
  after_initialize :set_default_date, if: :new_record?
  before_destroy :deletable?


  def summary
    "Credit Note ##{self.id} for Invoice ##{self.invoice_id}"
  end

  # Returns the entity (Client or Payee) who should receive the credit note
  def bill_to
    payee || client
  end

  # Returns true if this credit note is billed to the client directly
  def self_paid?
    payee.nil?
  end

  private

  def amount_cannot_exceed_invoice_amount
    return if invoice.nil? || amount.nil?

    if amount.abs > invoice.amount.abs
      errors.add(:amount, "cannot exceed invoice amount of #{invoice.amount.format}")
    end
  end

  def invoice_must_be_sent_or_paid
    unless invoice.sent? || invoice.paid?
      errors.add(:invoice, "must be sent or paid before issuing a credit note")
    end
  end

  def validate_editable_status
    non_status_changes = changed_attributes.keys - %w[status updated_at]
    non_status_changes.push(:text) if self.text.body_changed?

    # Check if any non-status fields are being changed when status is not 'created'
    non_status_changes_ok?(non_status_changes)

    # Check status transition rules
    status_change_ok?
  end

  def status_change_ok?
    if status_changed?
      case status_was
      when "created"
        # From 'created', can only go to 'sent'
        unless status == "sent"
          errors.add(:status, "invalid status transition")
        end
      when "sent"
        # From 'sent', cannot change to any other status
        errors.add(:status, "cannot change status once sent")
      end
    end
  end

  def non_status_changes_ok?(non_status_changes)
    return if status_was == "created"

    non_status_changes.each do |attr|
      errors.add(attr, "cannot be changed once the credit note has been sent")
    end
  end


  # Ensure amount is negative for credit notes
  def ensure_negative_amount
    if amount.present? && amount_pence.present? && amount_pence.positive?
      self.amount_pence = -amount_pence.abs
    end
  end

  # Sets the default date for new credit note records
  def set_default_date
    self.date ||= Date.current
  end

  # Returns true if this credit note can be deleted
  def deletable?
    throw :abort unless created?
  end
end

