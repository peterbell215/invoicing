class Message < ApplicationRecord
  has_rich_text :text
  has_many :messages_for_clients, dependent: :destroy
  has_many :clients, through: :messages_for_clients

  validates :text, presence: true

  # Scopes for finding active messages based on date
  scope :current, -> { where("`from_date` IS NULL OR `from_date` <= ?", Date.today)
                      .where("`until_date` IS NULL OR `until_date` >= ?", Date.today) }


  # Helper method to add this message to all clients
  def all_clients=(setting)
    setting = ActiveRecord::Type::Boolean.new.cast(setting)

    if setting
      messages_for_clients.build(client_id: nil)
      messages_for_clients.where.not(client_id: nil).destroy_all
    else
      messages_for_clients.where(client_id: nil).destroy_all
    end
  end

  # Helper method to determine if a message applies to all clients
  def all_clients
    messages_for_clients.exists?(client_id: nil)
  end

  # Helper method to take account of adding message to all clients or specific clients
  #
  # @param [Array<Client>, "all"] client_list
  def clients=(client_list)
    self.all_clients = false
    super(client_list)
  end

  # @see clients=
  def client_ids=(client_list_ids)
    self.all_clients = false
    super(client_list_ids)
  end

  # Helper method to add this message to a specific client
  def apply_to_client(client)
    messages_for_clients.find_or_create_by(client_id: client.id)
  end
end
