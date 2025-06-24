class Message < ApplicationRecord
  has_rich_text :text
  has_many :messages_for_clients, dependent: :destroy
  has_many :clients, through: :messages_for_clients

  # Scopes for finding active messages based on date
  scope :current, -> { where("`from_date` IS NULL OR `from_date` <= ?", Date.today)
                      .where("`until_date` IS NULL OR `until_date` >= ?", Date.today) }

  # Helper method to determine if a message applies to all clients
  def all_clients?
    messages_for_clients.exists?(client_id: nil)
  end

  # Helper method to take account of adding message to all clients or specific clients
  #
  # @param [Array<Client>, "all"] client_list
  def clients=(client_list)
    chenge_clients_of_message(client_list=="all") do
      super(client_list)
    end
  end

  # @see clients=
  def client_ids=(client_list_ids)
    chenge_clients_of_message(client_list_ids=="all") do
      super(client_list_ids)
    end
  end

  # Helper method to add this message to a specific client
  def apply_to_client(client)
    messages_for_clients.find_or_create_by(client_id: client.id)
  end

  # Helper method to add this message to multiple clients
  def apply_to_clients(client_ids)
    client_ids.each do |client_id|
      messages_for_clients.create(client_id: client_id)
    end
  end

  private

  def chenge_clients_of_message(all_set)
    if all_set
      messages_for_clients.create(client_id: nil)
      messages_for_clients.where.not(client_id: nil).destroy_all
    else
      messages_for_clients.where(client_id: nil).destroy_all
      yield
    end
  end
end
