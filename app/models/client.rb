# Provides details of a client including address.
class Client < ApplicationRecord
  has_many :client_sessions, dependent: :destroy
  has_many :fees, dependent: :destroy

  # There must be at least one fee record setup for the client
  validates :name, :address1, :town, presence: true
  validates :email, presence: true, uniqueness: true
  validates :postcode, format: { with: /\A[a-z]{1,2}\d[a-z\d]?\s*\d[a-z]{2}\z/i, message: 'is badly formed postcode' }

  validates :fees, presence: true
  validate :fees_must_not_overlap
  validates :new_rate, presence: { message: 'cannot be blank if New Rate From is set' }, if: :new_rate_from
  validates :new_rate_from, presence: { message: 'cannot be blank if New Rate is set' }, if: :new_rate

  attribute :new_rate, :money, default: -> { Money.new(6000) }
  attribute :new_rate_from, :date, default: -> { Time.zone.today }

  # Add a default fee record if none exists.
  after_initialize do |client|
    _build_active_fee if client.fees.empty?
  end

  before_save :create_new_rate

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

  def fees_must_not_overlap
    overlap_error = Fee.overlap?(self.fees)

    return unless overlap_error

    self.errors.add(:fees, "fee to #{overlap_error.to} overlaps with its successor")
  end
end

