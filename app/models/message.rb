class Message < ApplicationRecord
  has_rich_text :text
  has_many :messages_for_clients, dependent: :destroy
  has_many :clients, through: :messages_for_clients

  # Scopes for finding active messages based on date
  scope :current, -> { where("`from_date` IS NULL OR `from_date` <= ?", Date.today)
                      .where("`until_date` IS NULL OR `until_date` >= ?", Date.today) }

  # Helper method to determine if a message applies to all clients
  def applies_to_all_clients?
    messages_for_clients.exists?(client_id: nil)
  end

  # Helper method to add this message to all clients
  def apply_to_all_clients
    messages_for_clients.create(client_id: nil)
  end

  # Helper method to add this message to a specific client
  def apply_to_client(client)
    messages_for_clients.create(client: client)
  end

  # Helper method to add this message to multiple clients
  def apply_to_clients(client_ids)
    client_ids.each do |client_id|
      messages_for_clients.create(client_id: client_id)
    end
  end
end
