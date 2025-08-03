- Add system tests for client_sessions
- Add system tests for invoice
- Replace the call to the backend API for session rate with a data field on the option state that the controller looks at.
- When editing a Client, only create a new field, if the fees have actually changed.
- Once a session has been invoiced, it cannot be amended unless a credit note for the invoice
  has also been issued.
- Add a validator that checks that the amount reflects the sum of the client_sessions on create
  and update.
- Share the CSS for the client and payee index pages.
- I have created a modal dialog for payee delete.  This needs implenting with a Stimulus controller.  Also, approach needs replicating accross all
  pages.
- Sessions Index -> Show.  Get Content Missing message.
- Do not provide buttons on Session Index page for Edit and Delete if the session has been sent or paid.
- Instead, provide this offer the Show page, and show a modal informing that a credit note
  must be issued for the edited or deleted session.
- For a Created invoice provide buttons on the Show page for 'Edit', 'Delete'.
- In the system tests for invoices, make sure that 'Edit', 'Delete', etc buttons also work from the
  index page.
- On the Client Show page, Recent Sessions table has date in ISO format.  Set to locale format.
- In the Client Show page, Recent Sessions should show the status of the sessions.

