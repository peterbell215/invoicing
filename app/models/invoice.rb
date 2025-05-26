# Hold details of an invoice.
class Invoice < ApplicationRecord
  belongs_to :client
  has_many :client_sessions, dependent: :nullify

  monetize :amount_pence

  validates :date, presence: true

  enum :status, { created: 0, sent: 1, paid: 2 }

  # Deals with changing client sessions in invoice.
  # @param [HashWithIndifferentAccess] attrs
  def self.create(attrs)
    client_session_ids = attrs.delete(:client_session_ids)

    super(attrs)&.update_client_sessions(client_session_ids, existing_invoice: false)
  end

  def update_client_sessions(client_session_ids, existing_invoice: true)
    if existing_invoice
      existing_client_session_ids = ClientSession.where(invoice_id: self.id).pick(:id)
      remove_from_invoice = existing_client_session_ids - client_session_ids
      add_to_invoice = client_session_ids - existing_client_session_ids
      ClientSession.where(id: remove_from_invoice).update(invoice_id: nil)
    else
      add_to_invoice = client_session_ids
    end

    ClientSession.where(id: add_to_invoice).update(invoice_id: self.id) unless add_to_invoice.empty?
    self
  end
end