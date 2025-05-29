# Hold details of an invoice.
class Invoice < ApplicationRecord
  belongs_to :client
  has_many :client_sessions, dependent: :nullify

  monetize :amount_pence

  validates :date, presence: true
  validate :validate_editable_status, on: :update

  enum :status, { created: 0, sent: 1, paid: 2 }
  
  before_save :update_amount

  # Deals with changing client sessions in invoice.
  # @param [HashWithIndifferentAccess] attrs
  def self.create(attrs)
    client_session_ids = attrs.delete(:client_session_ids)

    super(attrs)&.update_client_sessions(client_session_ids, existing_invoice: false)
  end

  def update_client_sessions(client_session_ids, existing_invoice: true)
    if existing_invoice
      existing_client_session_ids = ClientSession.where(invoice_id: self.id).pluck(:id)
      remove_from_invoice = existing_client_session_ids - client_session_ids
      add_to_invoice = client_session_ids - existing_client_session_ids
      ClientSession.where(id: remove_from_invoice).update(invoice_id: nil)
    else
      add_to_invoice = client_session_ids
    end

    ClientSession.where(id: add_to_invoice).update(invoice_id: self.id) unless add_to_invoice.empty?
    update_amount
    self
  end
  
  private
  
  def update_amount
    self.amount = client_sessions.sum(&:fee)
  end
  
  def validate_editable_status
    if status_changed? && status_was != 'created'
      errors.add(:base, "Cannot modify an invoice that has been sent or paid")
    end
  end
end
