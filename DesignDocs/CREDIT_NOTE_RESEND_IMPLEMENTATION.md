# Credit Note Resend Implementation

## Overview
Implemented the ability to resend credit notes, mirroring the invoice send/resend functionality.

## Changes Made

### 1. Controller (`CreditNotesController#send_credit_note`)
- Removed the restriction that prevented resending sent credit notes
- Now allows sending credit notes regardless of their current status
- Attaches PDF only if not already attached (prevents duplicate attachments)
- Sends email via `CreditNoteMailer.credit_note_email`
- Marks as sent only if not already sent (`@credit_note.sent! unless @credit_note.sent?`)

### 2. View Updates

#### Created New Files
- `app/views/credit_notes/_buttons.html.erb` - Partial for credit note action buttons
- `app/views/shared/_send_credit_note_confirmation_dialog.html.erb` - Modal dialog for send confirmation
- `app/javascript/controllers/send_credit_note_confirmation_controller.js` - Triggers send confirmation event
- `app/javascript/controllers/send_credit_note_modal_controller.js` - Handles the send confirmation modal

#### Updated Files
- `app/views/credit_notes/show.html.erb`
  - Now uses `_buttons` partial
  - Includes send credit note confirmation dialog
  - Send button shown for all credit notes (not just created)
  
- `app/views/invoices/_credit_note_row.html.erb`
  - Updated to use modal-based send button pattern
  - Send button now shown for all credit notes on the index page
  
- `app/views/invoices/index.html.erb`
  - Added `send-credit-note-confirmation` controller to tbody
  - Included send credit note confirmation dialog

### 3. JavaScript Controllers
Created two new Stimulus controllers following the same pattern as invoice sending:

- **send_credit_note_confirmation_controller.js**: Dispatches `send-credit-note` custom event when button clicked
- **send_credit_note_modal_controller.js**: Listens for `send-credit-note` event and shows confirmation dialog

### 4. Tests
Updated `spec/system/credit_notes_spec.rb`:
- Modified "allows sending a created credit note" test to interact with the modal dialog
- Added new test "allows resending a sent credit note" to verify resend functionality
- All tests passing (9 examples, 0 failures)

## User Experience
- Users can now click "Send Credit Note" button on any credit note (created or sent)
- A confirmation dialog appears asking to confirm the send action
- Email is sent to the client
- Status is updated to "sent" (if not already)
- If already sent, the email is resent without changing the status

## Benefits
- Consistent behavior between invoices and credit notes
- Ability to resend credit note emails if needed (e.g., client didn't receive original)
- No duplicate PDF attachments created on resend
- Modal confirmation prevents accidental sends
- Comprehensive test coverage for both send and resend scenarios

## Date Implemented
November 16, 2025

