# Separating Payee from Client

The current design assumes that each client pays their own invoices.  This is not always the case.
Sometimes a third party is paying for the sessions on behalf of the client.

We will rename the existing Client table into Person table.  This will be a Single Table Inheritance
table so needs a type field.  The two derived classes for the Person table are Client and Payee.

We will add a self refence to the table called 'paid_by'.  If not set, then the client pays for
their own sessions.  If set, then the referenced Payee pays for the client_sessions.

The forms to create a new Person need to capture whether the record is a Client or a Payee.
If a client then the form needs a drop down.  The display in the dropdown corresponding to a nil
value should say 'Self Paying'.  The other values in the drop down should display the various
Payees.

A Payee cannot become a Client and vice-versa.  So when editing a Person, we should display but
not change the type.  However, a Client's payment source can change.

Invoice needs to also have two references now: Client and Payee.  If Payee is nil, then the Client
pays.  If Payee is non-nil then the Payee pays.  These can be set on an individual invoice
basis, but they inherit the initial setting from the Client record.

If Client and Payee are different, then the invoice needs to be addressed to the payee, but
should include a line showing that the invoice is for the specific client.
