- Add system tests for client_sessions
- Replace the call to the backend API for session rate with a data field on the option state that the controller looks at.
- When editing a Client, only create a new field, if the fees have actually changed.
- Once a session has been invoiced, it cannot be amended unless a credit note for the invoice
  has also been issued.
- Add a validator that checks that the amount reflects the sum of the client_sessions on create
  and update.
- Share the CSS for the client and payee index pages.
- Instead, provide this offer the Show page, and show a modal informing that a credit note
  must be issued for the edited or deleted session.
- In the Client Show page, Recent Sessions should show the status of the sessions.
- Add system tests for Client delete functionality.
- Provide unpaid sessions in the invoice draft.
- Authentication system
- Testing of ClientSessionsController#update for create and update error
- ClientController#destroy tests
- InvoicesController#update and #create failed save tests
- PayeeController#update and #create failed save tests
- PayeeController#update and #destroy tests
- Add a system test for the ClientController#update action
- 
