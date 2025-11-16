# Credit Notes Implementation - Complete Guide

## Overview
This document describes the complete implementation of the Credit Notes feature as specified in `Billing.md`.

## What Was Implemented

### 1. Database Schema Changes
The database was migrated to support Single Table Inheritance (STI) for billing documents:

```ruby
# Migration: AddBillingTypeAndCreditNoteFields
- Added `type` column to invoices table (for STI)
- Added `invoice_id` column (for credit notes to reference invoices)
- Added `reason` text column (for credit note justification)
- Renamed `invoices` table to `billings`
- Set existing records to type 'Invoice'
```

### 2. Model Architecture

#### Billing (Base Class)
```ruby
class Billing < ApplicationRecord
  self.table_name = 'billings'
  
  # Shared attributes:
  - id, client_id, payee_id, amount_pence, amount_currency
  - date, status, created_at, updated_at
  
  # Shared relationships:
  - belongs_to :client
  - belongs_to :payee (optional)
  - has_one_attached :pdf
  - has_rich_text :text
  
  # Shared methods:
  - bill_to (returns payee or client)
  - self_paid? (checks if billed directly to client)
end
```

#### Invoice (Inherits from Billing)
```ruby
class Invoice < Billing
  # Additional relationships:
  - has_many :client_sessions
  - has_many :credit_notes
  
  # Status enum: created, sent, paid
  
  # Key methods:
  - can_issue_credit_note? (returns true if sent or paid)
  - update_amount (calculates from client_sessions)
  - validate_editable_status (prevents editing sent/paid invoices)
end
```

#### CreditNote (Inherits from Billing)
```ruby
class CreditNote < Billing
  # Additional relationships:
  - belongs_to :invoice
  
  # Additional attributes:
  - invoice_id (references parent invoice)
  - reason (text explanation)
  
  # Status enum: created, sent, applied
  
  # Key validations:
  - invoice_must_be_sent_or_paid
  - amount_cannot_exceed_invoice_amount
  - ensure_negative_amount (before_validation callback)
  
  # Status transitions:
  created → sent → applied
end
```

### 3. Controllers

#### BillingsController
```ruby
def index
  # Lists all invoices with their associated credit notes
  @invoices = Invoice.includes(:client, :payee, :credit_notes)
                    .order(date: :desc, id: :desc)
end
```

#### CreditNotesController
Handles full CRUD operations for credit notes:
- `new` - Pre-populated with invoice details
- `create` - Validates and creates credit note
- `edit` - Only for 'created' status
- `update` - Updates credit note details
- `show` - Displays credit note
- `destroy` - Deletes 'created' credit notes
- `send_credit_note` - Marks as 'sent'
- `mark_applied` - Marks as 'applied'

### 4. Routes

```ruby
resources :billings, only: [:index]

resources :invoices, only: [:create, :show, :edit, :update, :destroy] do
  member do
    post :send_invoice
    patch :mark_paid
  end
  resources :credit_notes, only: [:new, :create]
end

resources :credit_notes, only: [:show, :edit, :update, :destroy] do
  member do
    post :send_credit_note
    patch :mark_applied
  end
end
```

### 5. Views Structure

#### Billings Index (`app/views/billings/index.html.erb`)
- Lists all billing documents
- Shows invoices with credit notes indented below
- Columns: Billing #, Type, Client, Date, Amount, Status, Actions

#### Credit Note Views
- `new.html.erb` - Create form with invoice details displayed
- `edit.html.erb` - Edit form (only for 'created' status)
- `show.html.erb` - Formatted credit note document
- `_form.html.erb` - Shared form partial

#### Partials
- `_billing_row.html.erb` - Invoice row in billings index
- `_credit_note_row.html.erb` - Credit note row (indented)

### 6. Navigation
Updated main navigation menu:
- Changed "Invoices" → "Billings"
- Links to `/billings` path

### 7. Action Buttons by Status

#### Invoice
- **created**: Edit, Delete, Send, Mark as Paid
- **sent**: Send, Mark as Paid, Issue Credit Note
- **paid**: Issue Credit Note

#### Credit Note
- **created**: Edit, Delete, Send
- **sent**: Mark as Applied
- **applied**: (No actions, final state)

## Usage Flow

### Creating a Credit Note
1. Navigate to Billings page
2. Find a sent or paid invoice
3. Click "Issue Credit Note"
4. Enter credit amount (≤ invoice amount)
5. Enter reason for credit
6. Click "Create Credit Note"

### Credit Note Lifecycle
1. **Created** → Edit details, or Send to client, or Delete
2. **Sent** → Once sent, assumed it is applied.  Therefore, final state, no further changes

## Data Integrity

### Validations
- Credit notes can only be created for sent/paid invoices
- Credit amount cannot exceed original invoice amount
- Amount is automatically stored as negative
- Reason is required
- Status transitions are enforced

### Constraints
- Cannot edit credit note after sending
- Cannot delete credit note after sending
- Status can only move forward (created → sent → applied)

## Testing

A comprehensive test file was created at `spec/system/credit_notes_spec.rb` covering:
- Creating credit notes
- Amount validation
- Status restrictions
- Lifecycle transitions
- Billings index display

Factory created at `spec/factories/credit_notes.rb` for testing.

## Files Created/Modified

### Created Files
- `app/models/billing.rb`
- `app/models/credit_note.rb`
- `app/controllers/billings_controller.rb`
- `app/controllers/credit_notes_controller.rb`
- `app/views/billings/` (directory with index and partials)
- `app/views/credit_notes/` (directory with all credit note views)
- `db/migrate/[timestamp]_add_billing_type_and_credit_note_fields.rb`
- `spec/system/credit_notes_spec.rb`
- `spec/factories/credit_notes.rb`
- `DesignDocs/IMPLEMENTATION_SUMMARY.md`

### Modified Files
- `app/models/invoice.rb` (inherit from Billing, add credit_notes relationship)
- `app/controllers/invoices_controller.rb` (add mark_paid action)
- `app/views/layouts/application.html.erb` (navigation menu)
- `app/views/invoices/_buttons.html.erb` (Issue Credit Note button)
- `app/views/invoices/show.html.erb` (back link)
- `config/routes.rb` (billings and credit_notes routes)

## Database Commands

```bash
# Run migration
rails db:migrate

# Run for test environment
RAILS_ENV=test rails db:migrate

# Rollback if needed
rails db:rollback
```

## Verification

Test the implementation:

```bash
# Run credit notes specs
bundle exec rspec spec/system/credit_notes_spec.rb

# Start server and test manually
rails server
# Visit http://localhost:3000/billings
```

## Future Enhancements (Not Implemented)

1. **Email notifications** for credit notes
2. **PDF generation** for credit notes
3. **Automatic invoice balance adjustment** when credit notes are applied
4. **Credit note totals** on invoice show page
5. **Reporting** for credit notes issued
6. **Refund tracking** linked to credit notes

## Notes

- Credit note amounts are stored as negative values in the database
- The form displays positive values for user convenience
- Amount conversion happens in the controller's `credit_note_params` method
- STI allows both Invoice and CreditNote to share the same table while maintaining distinct behavior
- Navigation was changed from "Invoices" to "Billings" to reflect the combined nature of the page

