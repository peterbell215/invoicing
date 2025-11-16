# Adding Credit Notes

## Overview

We would like to add the ability to issue credit notes to customers in our billing system. Where a customer does not
agree with an invoice, a credit note can be issued to adjust the amount owed.  This can be upto the full amount of the
invoice.

## Changes to the data model

### Billing Superclass

Currently, we have an `Invoice` model that tracks invoices issued to customers. We need to create a superclass called
Billing that serves as a parent for both `Invoice` and the new `CreditNote` model.

The Billing model will share the following attributes across both Invoices and Credit Notes:
- `id`: Unique identifier
- `customer_id`: Reference to the customer
- `amount`: Total amount (positive for invoices, negative for credit notes)
- `status`: Status of the billing document (e.g., 'draft', 'issued', 'paid', 'voided')
- `issued_at`: Timestamp when the document was issued

It shares the following relationships:
- Belongs to `Customer`

### Invoice Model

The `Invoice` model will inherit from the `Billing` superclass and retain its existing attributes and relationships.

- `due_at`: Timestamp when payment is due (only for invoices)

The ClientSession relationship remains unchanged and is used to identify which sessions are billed in the invoice.

### CreditNote Model

The `CreditNote` model will have the following additional attributes:
- `invoice_id`: Reference to the original invoice being credited
- `reason`: Text field to describe the reason for issuing the credit note

## Changes to the User Interface

### Menu at the top of the screen

Rename the "Invoices" menu item to "Billings".  Change the file structure in the views directory to reflect this change.

### Invoice Index Page

Update the Invoice index page to list both Invoices and Credit Notes. Change the column Invoice # to Billing #. Add a
new column Type to indicate whether the billing document is an Invoice or a Credit Note.  Credit Notes should be in the
line below their associated Invoice, and indented slightly.

In the action column, create for invoices that are marked as 'sent' or 'paid', a button to issue a Credit Note.
This button will lead to a new Credit Note creation page, pre-populated with the invoice details.  This button should
not be available for invoices that are in 'created' status.

Add a View link for Credit Notes that takes the user to the Credit Note show page.  Mirror the existing buttons
dependent on state of the Invoice for Credit Notes.  For Credit Notes the states are 'created', 'sent', and 'applied'.

Credit Notes that are in the 'created' status should have a 'Send' button that allows the user to send the Credit Note
to the customer.  Equally, it should have a 'Delete' button to remove the Credit Note.

For Credit Notes that are in 'created' status, add an Edit link that takes the user to the Credit Note edit page.

### Credit Note Creation Page and Edit Page

The Credit Note creation and edit pages should allow the user to create a credit note based on an existing invoice. The page
should display the invoice details, including the customer information, invoice number, date, and amount. The user
should be able to specify the amount to be credited (up to the full amount of the invoice) and provide a reason for
issuing the credit note.

A 'Create' or 'Update' button should be provided to save the credit note.

### Invoice Show Page

The same buttons to issue a Credit Note should be available on the Invoice show page for invoices.

### Credit Note Show Page

The Credit Note show page should display all relevant details of the credit note.  It should have the same action buttons
at the top of the page as the Invoice show page, dependent on the state of the Credit Note.

## Changes to the Controllers

A BillingsController should be created to handle generating the Billing Index.

Access to Credit Notes should be managed through a separate controller called `CreditNotesController`.  The existing
`InvoicesController` should remain largely unchanged, except for the addition of the button to issue Credit Notes.

The `CreditNotesController` should have the following actions:
- `new`: Display the Credit Note creation page, pre-populated with invoice details.
- `create`: Handle the submission of the Credit Note creation form.
- `edit`: Display the Credit Note edit page.
- `update`: Handle the submission of the Credit Note edit form.
- `show`: Display the Credit Note details.
