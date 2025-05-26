json.id @client.id
json.current_rate @client.current_rate.to_f
json.url client_session_url(@client, format: :json)