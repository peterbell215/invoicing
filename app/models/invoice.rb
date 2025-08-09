# Hold details of an invoice.
class Invoice < ApplicationRecord
  belongs_to :client
  belongs_to :payee, class_name: "Payee", optional: true
  has_many :client_sessions, dependent: :nullify
  has_one_attached :pdf
  has_rich_text :text

  monetize :amount_pence

  validates :date, presence: true
  validate :validate_editable_status, on: :update
  before_validation :set_payee_from_client, on: :create

  enum :status, { created: 0, sent: 1, paid: 2 }

  before_save :update_amount
  after_initialize :populate_text_from_messages, if: :new_record?
  after_initialize :set_default_date, if: :new_record?
  before_destroy :deletable?

  def summary
    "Invoice ##{self.id} for #{self.client.name}"
  end

  # Returns the entity (Client or Payee) who should receive the invoice
  def bill_to
    payee || client
  end

  # Returns true if this invoice is billed to the client directly
  def self_paid?
    payee.nil?
  end

  private

  def update_amount
    self.amount= client_sessions.sum(&:fee)
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
        # From 'created', can go to 'sent' or 'paid' (both allowed)
        unless %w[sent paid].include?(status)
          errors.add(:status, "invalid status transition")
        end
      when "sent"
        # From 'sent', can only go to 'paid'
        unless status == "paid"
          errors.add(:status, "can only be marked as 'paid' after being 'sent'")
        end
      when "paid"
        # From 'paid', cannot change to any other status
        errors.add(:status, "can only be marked as 'paid' after being 'sent'")
      end
    end
  end

  def non_status_changes_ok?(non_status_changes)
    return if status_was == "created"

    non_status_changes.each do |attr|
      errors.add(attr, "cannot be changed once the invoice has been sent or paid")
    end
  end

  # Set the payee based on the client's payment arrangement
  def set_payee_from_client
    self.payee ||= client.paid_by if client&.paid_by.present?
  end

  # Populate the text field with relevant messages when creating a new invoice
  def populate_text_from_messages
    return if client.nil? # Guard clause for cases where client isn't set yet

    # Get current messages for this client (including global messages)
    client_messages = client.messages.current
    global_messages = Message.joins(:messages_for_clients)
                            .where(messages_for_clients: { client_id: nil })
                            .current

    relevant_messages = (client_messages + global_messages).uniq.sort_by(&:created_at)

    return if relevant_messages.empty?

    # Build formatted text from messages
    message_content = relevant_messages.map do |message|
      message.text.to_s
    end.join("\n\n")

    # Set the rich text content
    self.text = message_content
  end

  # Sets the default date for new invoice records
  def set_default_date
    self.date ||= Date.current
  end

  # Returns true if this invoice can be deleted
  def deletable?
    throw :abort unless created?
  end
end
