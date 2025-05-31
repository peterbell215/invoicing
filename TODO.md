- The CSS is a bit all over the place.  Consolidate them so that the majority are in the css files.
- Add system tests for client_sessions
- Add system tests for invoice
- Add an ability to allow the sessions to be paid by someone else
- Details of Katy's invoicing to be held in the database.
- Replace the call to the backend API for session rate with a data field on the option state that the controller looks at.
- When editing a Client, only create a new field, if the fees have actually changed.
- Once a session has been invoiced, it cannot be amended unless a credit note for the invoice
  has also been issued.
- Add a validator that checks that the amount reflects the sum of the client_sessions on create
  and update.
- 