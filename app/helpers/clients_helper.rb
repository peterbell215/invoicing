module ClientsHelper
  # Concatenates all address fields into a single formatted address string
  def full_address(client)
    address_parts = [
      client.address1,
      client.address2,
      client.town,
      client.postcode
    ].compact.reject(&:blank?)
    
    address_parts.join(", ")
  end
end
