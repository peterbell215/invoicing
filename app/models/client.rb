# Provides details of a client including address.
class Client < ApplicationRecord
  include Person

  has_many :client_sessions, dependent: :destroy
  has_many :fees, dependent: :destroy
  belongs_to :paid_by, class_name: 'Payee', optional: true
  has_many :messages_for_clients, dependent: :destroy
  has_many :messages, through: :messages_for_clients
  has_many :invoices, dependent: :nullify

  validates :fees, presence: true
  validate :fees_must_not_overlap

  # Set clients to active by default
  attribute :active, :boolean, default: true

  attribute :new_rate, :money, default: Money.new(6000, 'GBP')
  attribute :new_rate_from, :date, default: -> { Time.zone.today }
  validates :new_rate, presence: { message: 'cannot be blank if New Rate From is set' }, if: :new_rate_from
  validates :new_rate_from, presence: { message: 'cannot be blank if New Rate is set' }, if: :new_rate

  # Add a default fee record if none exists.
  after_initialize do |client|
    _build_active_fee if client.fees.empty?
  end

  before_save :create_new_rate

  def summary
    "#{self.name} (#{self.id})"
  end

  def as_json(options = {})
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || {}).merge({ methods: %i[current_rate] }))
  end

  # Returns the current hourly rate for this client
  #
  # @return Money
  def current_rate
    self.current_fee&.hourly_charge_rate
  end

  # returns since when the current hourly rate for this client applies
  # @return Date
  def current_rate_since
    self.current_fee&.from
  end

  # Sets the current fee for client sessions if different from current fee as held in database.  Updates the
  # current rate in the database to be up to yesterday, and creates a new fees record starting
  # today with an open ended charge period.
  # @return [Money]
  def create_new_rate
    active_fee = self.current_fee

    if active_fee.nil?
      # No record exists yet, so create a new one.
      _build_active_fee
    elsif active_fee.hourly_charge_rate != self.new_rate
      # Something has changed, so ...
      if active_fee.persisted?
        # If this is a persisted (ie existing) fee, then amend date period and add the new record.
        active_fee.update!(to: self.new_rate_from - 1.day)
        _build_active_fee
      else
        # If not yet persisted, then update existing unsaved record.
        active_fee.hourly_charge_rate = self.new_rate
      end
    end
  end

  def _build_active_fee
    self.fees << Fee.new(from: self.new_rate_from, to: nil, hourly_charge_rate: self.new_rate)
  end

  # Returns the current fee record.
  def current_fee
    if self.id
      self.fees.find_by(to: nil)
    else
      self.fees.find { |fee| fee.to.nil? }
    end
  end

  def uninvoiced_sessions
    self.client_sessions.where(invoice_id: nil)
  end

  # Returns the total amount of uninvoiced sessions for this client
  #
  # @return Money
  def uninvoiced_amount
    Money.new(uninvoiced_sessions.sum(&:fee))
  end

  def fees_must_not_overlap
    overlap_error = Fee.overlap?(self.fees)

    return unless overlap_error

    self.errors.add(:fees, "fee to #{overlap_error.to} overlaps with its successor")
  end

  # Returns all messages applicable to this client,
  # including global messages that apply to all clients
  def applicable_messages
    Message.current.left_joins(:messages_for_clients)
           .where('messages_for_clients.client_id = ? OR messages_for_clients.client_id IS NULL', id)
           .distinct
  end
end
