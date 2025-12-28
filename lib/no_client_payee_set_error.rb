# Exception raised when attempting to set self_paid to true on an invoice
# for a client that does not have a payee configured
class NoClientPayeeSetError < StandardError
  def initialize(msg = "Cannot set self_paid to true: client does not have a payee configured")
    super
  end
end
