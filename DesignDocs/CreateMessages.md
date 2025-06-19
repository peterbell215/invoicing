I want to create the ability to add messages to the invoices.

Messages can apply to:

- an individual client
- a set of clients
- all clients

This is best implemented as a join table 'messages_for_clients' with fields client_id and message_id.
If a message applies to all clients, then the client_id should be set to nil.  

A message has a `from` date and an `until` date.
If the `from` date is set to nil, then messages should be included as soon as it is saved.
If the 'until' date is set to nil, then messages should be included forever.

Message text should be captured using Action Text.
