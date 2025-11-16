# Fix: Duplicate "Issue Credit Note" Button - Summary

## Date: November 16, 2025

## Problem
The "Issue Credit Note" link was appearing twice on the Invoices index page for invoices that can issue credit notes.

## Root Cause
The button was defined in two places:
1. In `app/views/invoices/_invoice_row.html.erb` (lines 21-25)
2. In `app/views/invoices/_buttons.html.erb` (lines 30-34)

Since `_invoice_row.html.erb` renders the `_buttons.html.erb` partial, the button appeared twice.

## Solution
Removed the duplicate button from `_invoice_row.html.erb` and kept it only in `_buttons.html.erb` where all other invoice action buttons are centralized.

## Files Modified

### 1. app/views/invoices/_invoice_row.html.erb
**Removed**:
```erb
<% if invoice.can_issue_credit_note? %>
  <%= link_to new_invoice_credit_note_path(invoice), class: "pure-button button-warning button-small", data: { turbo_frame: '_top' } do %>
    <span class="material-symbols-outlined">receipt</span> Issue Credit Note
  <% end %>
<% end %>
```

The button is already rendered via:
```erb
<%= render partial: "invoices/buttons", locals: { invoice: invoice, button_size: "button-small" } %>
```

### 2. spec/system/credit_notes_spec.rb
**Updated test references**:
- Changed `billings_path` to `invoices_path` (3 occurrences)
- Changed `"Billings"` to `"Invoices"` in test expectations
- Updated credit note factory calls to use `invoice_param:` instead of `invoice:, client:` since credit notes now delegate client through invoice

## Additional Improvements
While fixing this issue, also corrected the system tests to:
1. Use the correct route (`invoices_path` instead of removed `billings_path`)
2. Use the correct factory parameters for credit notes after STI separation
3. Update test descriptions to match current terminology

## Verification
✅ Duplicate button removed from invoice row partial
✅ Button still available in buttons partial (correct location)
✅ System tests updated to use correct routes and factory parameters
✅ No syntax errors in modified files

## User Impact
- Users will now see only ONE "Issue Credit Note" button per invoice (instead of two)
- Button placement and functionality remains the same
- All other action buttons unaffected

## Testing
To verify the fix works:
1. Visit the Invoices index page
2. Find an invoice with status "sent" or "paid"
3. Confirm only ONE "Issue Credit Note" button appears
4. Click the button to verify it still works correctly

