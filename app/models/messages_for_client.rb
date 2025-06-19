# Join table to link a client to a specific message.  Note that if a message appplies to all
# clients, then the client_id should be set to nil.
class MessagesForClient < ApplicationRecord
  belongs_to :message
  belongs_to :client, optional: true
end
