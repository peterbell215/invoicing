# Payee represents a person who pays for client services
class Payee < ApplicationRecord
  include Person

  has_many :clients, foreign_key: 'paid_by_id'
  has_many :invoices, foreign_key: 'payee_id'

  def summary
    "#{self.name} (#{self.id})"
  end

  # A payee can have many clients they pay for
  def client_count
    clients.count
  end

  # Get all sessions across all clients this payee pays for
  def all_client_sessions
    ClientSession.joins(:client).where(clients: { paid_by_id: self.id })
  end
end
