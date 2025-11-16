# Separation of Invoice and CreditNote Models - Completion Summary

## Date: November 16, 2025

## Overview
Successfully separated the STI (Single Table Inheritance) Billing model into separate Invoice and CreditNote models with their own tables. Also removed the BillingsController and moved all functionality to the InvoicesController.

## Changes Made

### 1. Database Migration
- **Created**: `db/migrate/20251116142140_separate_invoices_and_credit_notes.rb`
- **Actions**:
  - Created new `credit_notes` table with columns: invoice_id, date, amount_pence, amount_currency, reason, status
  - Migrated any existing credit notes from billings table
  - Renamed `billings` table back to `invoices`
  - Removed STI columns: `type`, `invoice_id`, `reason` from invoices table
  - Added foreign key constraint from credit_notes to invoices

### 2. Models Updated

#### Invoice Model (`app/models/invoice.rb`)
- Changed inheritance from `Billing` to `ApplicationRecord`
- Added back all associations: `belongs_to :client`, `belongs_to :payee`, `has_many :client_sessions`, `has_many :credit_notes`
- Added back monetize, validations, and callbacks
- Added helper methods: `bill_to`, `self_paid?`, `set_default_date`
- Kept enum: `{ created: 0, sent: 1, paid: 2 }`

#### CreditNote Model (`app/models/credit_note.rb`)
- Changed inheritance from `Billing` to `ApplicationRecord`
- Added delegation: `delegate :client, :payee, to: :invoice, allow_nil: true`
- Client and payee accessed through parent invoice (no direct columns)
- Added enum: `{ created: 0, sent: 1, applied: 2 }`
- Kept all validations and business logic
- Fixed status transition logic to properly handle 'applied' state

#### Removed
- **Deleted**: `app/models/billing.rb` - No longer needed

### 3. Controllers Updated

#### Removed BillingsController
- **Deleted**: `app/controllers/billings_controller.rb`

#### Updated InvoicesController
- Updated `index` action to include credit notes:
  ```ruby
  @invoices = Invoice.includes(:client, :payee, :credit_notes).order(date: :desc, id: :desc)
  ```

### 4. Routes Updated (`config/routes.rb`)
- **Removed**: `resources :billings, only: [:index]`
- **Updated**: Added `index` to invoices resources
- **Result**: `invoices_path` now points to the invoice index showing both invoices and credit notes

### 5. Views Updated

#### Removed Billings Views
- **Deleted**: `app/views/billings/` directory and all contents

#### Updated Invoice Views
- **Updated**: `app/views/invoices/index.html.erb`
  - Shows both invoices and credit notes in a unified view
  - Added "Type" column to distinguish between Invoice and Credit Note
  - Credit notes appear indented below their parent invoice
  
- **Created**: `app/views/invoices/_invoice_row.html.erb`
  - Partial for rendering invoice rows
  - Shows invoice number, type badge, client, date, amount, status
  - Action buttons for View, Edit, Send, Delete, Mark Paid, Issue Credit Note
  
- **Created**: `app/views/invoices/_credit_note_row.html.erb`
  - Partial for rendering credit note rows
  - Styled with lighter background and indentation
  - Action buttons for View, Edit, Send, Delete, Mark Applied

- **Updated**: `app/views/invoices/show.html.erb`
  - Changed back link from `billings_path` to `invoices_path`
  - Updated button text from "Back to Billings" to "Back to Invoices"

#### Updated Credit Note Views
- **Updated**: `app/views/credit_notes/show.html.erb`
  - Changed back link from `billings_path` to `invoices_path`
  - Updated button text from "Back to Billings" to "Back to Invoices"

- **Updated**: `app/views/credit_notes/_form.html.erb`
  - Changed cancel link from `billings_path` to `invoices_path`

#### Updated Layout
- **Updated**: `app/views/layouts/application.html.erb`
  - Changed navigation menu item from "Billings" to "Invoices"
  - Changed route from `billings_path` to `invoices_path`

### 6. Factory Updated
- **Updated**: `spec/factories/credit_notes.rb`
  - Removed `client` and `payee` associations (now accessed through invoice)
  - Simplified to only require `invoice_param` transient attribute

## Benefits of This Separation

1. **Clearer Data Model**
   - Separate tables make the data structure more explicit
   - No STI complexity or type column queries
   - Easier to understand and maintain

2. **Independent Enums**
   - Invoice has its own status enum: created, sent, paid
   - CreditNote has its own status enum: created, sent, applied
   - No conflicts or workarounds needed

3. **Simplified Relationships**
   - CreditNote delegates client/payee to invoice
   - No duplicate data storage
   - Easier to ensure consistency

4. **Better Performance**
   - No type column filtering needed
   - Direct table access
   - Simpler queries

5. **Clearer Controller Structure**
   - InvoicesController handles invoices
   - CreditNotesController handles credit notes
   - No ambiguous BillingsController

## Testing Verification

The following should be tested:

1. ✅ Migration ran successfully
2. ✅ Routes updated correctly (no billings_path, invoices_path works)
3. ✅ Models load without errors
4. ✅ Credit note can access client through invoice delegation
5. [ ] Invoice index displays both invoices and credit notes
6. [ ] Creating a credit note works correctly
7. [ ] Credit note status transitions work (created → sent → applied)
8. [ ] All links and navigation work correctly

## Files Modified/Created/Deleted

### Created
- `db/migrate/20251116142140_separate_invoices_and_credit_notes.rb`
- `app/views/invoices/_invoice_row.html.erb`
- `app/views/invoices/_credit_note_row.html.erb`

### Modified
- `app/models/invoice.rb`
- `app/models/credit_note.rb`
- `app/controllers/invoices_controller.rb`
- `app/views/invoices/index.html.erb`
- `app/views/invoices/show.html.erb`
- `app/views/credit_notes/show.html.erb`
- `app/views/credit_notes/_form.html.erb`
- `app/views/layouts/application.html.erb`
- `config/routes.rb`
- `spec/factories/credit_notes.rb`
- `DesignDocs/IMPLEMENTATION_SUMMARY.md`

### Deleted
- `app/models/billing.rb`
- `app/controllers/billings_controller.rb`
- `app/views/billings/` (entire directory)

## Next Steps

1. Run the application and verify all functionality works
2. Test creating, editing, and managing invoices
3. Test creating and managing credit notes
4. Verify navigation flows correctly
5. Update any system tests that reference billings_path or BillingsController

