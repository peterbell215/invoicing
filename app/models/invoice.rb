# Hold details of an invoice.
class Invoice < ApplicationRecord
  belongs_to :client
  has_many :client_sessions, dependent: :nullify

  monetize :amount_pence

  validates :date, presence: true
  validate :validate_editable_status, on: :update

  enum :status, { created: 0, sent: 1, paid: 2 }

  private

  def validate_editable_status
    if status_changed? && status_was != 'created'
      errors.add(:base, "Cannot modify an invoice that has been sent or paid")
    end
  end
end
