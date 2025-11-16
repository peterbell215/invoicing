# Invoice and Credit Notes Implementation Summary

## Completed Changes

### Database Changes
- ✅ Created separate `credit_notes` table (separated from `invoices` table)
- ✅ Added `invoice_id` column in credit_notes to reference parent invoice
- ✅ Added `reason` column for credit notes
- ✅ Added `date`, `amount_pence`, `amount_currency`, `status` columns to credit_notes
- ✅ Removed STI approach - Invoice and CreditNote are now separate tables
- ✅ Migrated any existing credit notes from old structure

### Models Created/Updated
- ✅ Removed `Billing` base model (no longer using STI)
- ✅ Updated `Invoice` to inherit from `ApplicationRecord` directly
- ✅ Created `CreditNote` model inheriting from `ApplicationRecord`
- ✅ Added delegation in CreditNote: `client` and `payee` accessed through invoice
- ✅ Added validation to ensure credit notes can only be issued for sent/paid invoices
- ✅ Added validation to ensure credit amount doesn't exceed invoice amount
- ✅ Added status transitions for credit notes (created → sent → applied)
- ✅ Added `can_issue_credit_note?` method to Invoice model

### Controllers Created/Updated
- ✅ Removed `BillingsController` (functionality moved to InvoicesController)
- ✅ Updated `InvoicesController` index to show both invoices and credit notes
- ✅ Created `CreditNotesController` with full CRUD actions plus:
  - `send_credit_note` - to mark credit note as sent
  - `mark_applied` - to mark credit note as applied
- ✅ Updated `InvoicesController` to add `mark_paid` action
- ✅ Kept existing invoice functionality intact

### Routes Updated
- ✅ Removed `resources :billings` route
- ✅ Updated invoices routes to include index action
- ✅ Added nested route for creating credit notes under invoices
- ✅ Added credit notes routes with custom member actions
- ✅ Updated invoice routes to include mark_paid action

### Views Created/Updated
- ✅ Updated `app/views/invoices/index.html.erb` - shows invoices with credit notes
- ✅ Created `app/views/invoices/_invoice_row.html.erb` - invoice row partial
- ✅ Created `app/views/invoices/_credit_note_row.html.erb` - credit note row partial
- ✅ Created `app/views/credit_notes/new.html.erb` - create credit note form
- ✅ Created `app/views/credit_notes/edit.html.erb` - edit credit note form
- ✅ Created `app/views/credit_notes/_form.html.erb` - credit note form partial
- ✅ Created `app/views/credit_notes/show.html.erb` - credit note details page
- ✅ Updated `app/views/layouts/application.html.erb` - navigation points to invoices
- ✅ Updated `app/views/invoices/_buttons.html.erb` - added "Issue Credit Note" button
- ✅ Updated `app/views/invoices/show.html.erb` - back link to invoices
- ✅ Updated `app/views/credit_notes/show.html.erb` - back link to invoices
- ✅ Updated `app/views/credit_notes/_form.html.erb` - cancel link to invoices

### Features Implemented
1. **Invoice Index Page**
   - Lists all invoices with their associated credit notes
   - Credit notes appear indented below their parent invoice
   - Separate Type column shows "Invoice" or "Credit Note"
   - Action buttons appropriate to each document type and status

2. **Credit Note Creation**
   - Can only be created for sent or paid invoices
   - Pre-populated with invoice details
   - User specifies credit amount (validated not to exceed invoice amount)
   - User provides reason for credit note
   - Amount automatically stored as negative

3. **Credit Note Lifecycle**
   - **Created**: Can edit, send, or delete
   - **Sent**: Can mark as applied
   - **Applied**: Final state, no further changes allowed

4. **Visual Indicators**
   - Color-coded badges for Invoice vs Credit Note
   - Status badges showing document state
   - Material icons for all actions
   - Indented display of credit notes under invoices

## Testing Required
- [ ] Test creating a credit note for a sent invoice
- [ ] Test validation: cannot create credit note for created invoice
- [ ] Test validation: credit amount cannot exceed invoice amount
- [ ] Test editing a created credit note
- [ ] Test sending a credit note
- [ ] Test marking credit note as applied
- [ ] Test deleting a created credit note
- [ ] Test that credit notes appear correctly in invoice index
- [ ] Test navigation flow (Invoices → Invoice → Create Credit Note → View Credit Note)

## Known Limitations
- Credit notes do not automatically adjust invoice balance
- No email functionality for credit notes yet (could be added similar to invoices)
- No PDF generation for credit notes yet (could be added similar to invoices)

