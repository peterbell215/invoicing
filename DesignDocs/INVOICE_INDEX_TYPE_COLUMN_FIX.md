# Invoice Index Mark as Paid - Missing Type Column Fix

## Issue
When marking an invoice as paid from the Invoice index page, the turbo stream replacement was using a partial (`_invoices_row.html.erb`) that was missing the "Type" column, causing table misalignment.

## Root Cause
The application had two similar invoice row partials:
1. `_invoice_row.html.erb` (singular) - Used in the initial page render, includes all columns including Type
2. `_invoices_row.html.erb` (plural) - Used in turbo stream updates, was missing the Type column

When `InvoicesController#update` responded to a mark-as-paid request from the index page, it used a turbo stream to replace the row with the `_invoices_row.html.erb` partial, which was missing the Type column.

## Solution

### 1. Merged Duplicate Partials
Since both partials served the same purpose and now had identical content, merged them into a single partial:
- Kept `_invoice_row.html.erb` as the single source of truth
- Deleted `_invoices_row.html.erb` 
- Updated `InvoicesController#update` to use `invoices/invoice_row` instead of `invoices/invoices_row`

The unified partial includes:
- All table columns including the Type column with "Invoice" badge
- Consistent CSS styling for billing type badges
- Proper button rendering via the buttons partial

### 2. Fixed Brittle Tests
Updated three tests in `spec/system/invoices_spec.rb` that were using brittle `nth-child` selectors:
- "shows correct status badges for different invoice statuses"
- "shows delete button only for created invoices"  
- "shows send button for created and sent invoices but not paid invoices"

Changed from:
```ruby
within("tbody tr:nth-child(2)") do
  # assertions
end
```

To:
```ruby
within("#invoice_#{sent_invoice.id}") do
  # assertions
end
```

This makes the tests more robust and immune to changes in row ordering or the presence of credit note rows.

## Files Modified
- `/app/views/invoices/_invoices_row.html.erb` - Deleted (merged into `_invoice_row.html.erb`)
- `/app/views/invoices/_invoice_row.html.erb` - Now serves as the single invoice row partial
- `/app/controllers/invoices_controller.rb` - Updated turbo stream to use `invoices/invoice_row`
- `/spec/system/invoices_spec.rb` - Updated three tests to use specific invoice IDs

## Verification
All invoice system tests passing (31 examples, 0 failures), including:
- Mark as paid functionality from index page
- Mark as paid functionality from show page
- All index page display tests

## Date Fixed
November 16, 2025

