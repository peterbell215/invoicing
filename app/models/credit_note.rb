# Represents a credit note issued against an invoice
class CreditNote < Billing
  belongs_to :invoice, class_name: 'Invoice'

  validates :invoice_id, presence: true
  validates :reason, presence: true
  validate :amount_cannot_exceed_invoice_amount
  validate :invoice_must_be_sent_or_paid
  validate :validate_editable_status, on: :update

  before_validation :set_payee_from_invoice, on: :create
  before_validation :ensure_negative_amount
  before_destroy :deletable?

  # Override status enum to include 'applied' instead of 'paid'
  enum :status, { created: 0, sent: 1 }

  def summary
    "Credit Note ##{self.id} for Invoice ##{self.invoice_id}"
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
        # From 'created', can go to 'sent' or 'applied'
        unless %w[sent applied].include?(status)
          errors.add(:status, "invalid status transition")
        end
      when "sent"
        # From 'applied', cannot change to any other status
        errors.add(:status, "cannot change status once sent")
      end
    end
  end

  def non_status_changes_ok?(non_status_changes)
    return if status_was == "created"

    non_status_changes.each do |attr|
      errors.add(attr, "cannot be changed once the credit note has been sent or applied")
    end
  end

  # Set the payee based on the invoice's payee
  def set_payee_from_invoice
    self.payee ||= invoice.payee if invoice&.payee.present?
    self.client ||= invoice.client if invoice&.client.present?
  end

  # Ensure amount is negative for credit notes
  def ensure_negative_amount
    if amount.present? && amount_pence.present? && amount_pence.positive?
      self.amount_pence = -amount_pence.abs
    end
  end

  # Returns true if this credit note can be deleted
  def deletable?
    throw :abort unless created?
  end
end

