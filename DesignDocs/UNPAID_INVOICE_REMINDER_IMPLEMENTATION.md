# Unpaid Invoice Reminder Implementation

## Date: December 13, 2025

## Overview
Implemented a feature that automatically includes reminders for unpaid invoices when creating a new invoice draft. This allows users to be aware of outstanding invoices and optionally include or modify the reminder text before sending the invoice.

## Implementation Details

### Model Changes

**File**: `app/models/invoice.rb`

#### Modified Methods

1. **`populate_text_from_messages`** - Enhanced to include unpaid invoice reminders
   - Calls `populate_text_with_unpaid_invoices` to get reminder text
   - Combines reminder with existing messages
   - Preserves the original message functionality
   - Cleaner and more focused on orchestrating content assembly

2. **`populate_text_with_unpaid_invoices`** - New private method
   - Checks for unpaid invoices (status not equal to 'paid') for the client
   - Excludes the current invoice being created from the check
   - Returns nil if no unpaid invoices exist
   - Delegates formatting to `build_unpaid_invoice_reminder`

3. **`build_unpaid_invoice_reminder`** - New private method
   - For single unpaid invoice: "REMINDER: Invoice #X dated DD/MM/YYYY remains unpaid."
   - For multiple unpaid invoices: "REMINDER: The following invoices remain unpaid: #X (DD/MM/YYYY), #Y (DD/MM/YYYY)."
   - Orders multiple invoices by date for consistent display

### Behavior

- **When creating a new invoice**: The text field is automatically populated with:
  1. Unpaid invoice reminder (if any unpaid invoices exist)
  2. Relevant messages (if any current messages exist)
  3. Parts are separated by double newlines

- **User control**: Users can edit or completely remove the reminder text before creating the invoice

- **No duplication**: The reminder is only added during initialization (via `after_initialize` callback), so reloading an invoice doesn't duplicate the reminder

## Tests Created

### Unit Tests (spec/models/invoice_spec.rb)

Added 6 comprehensive tests in the "unpaid invoice reminder" describe block:

1. **Single unpaid invoice**: Verifies reminder is included with correct format
2. **Multiple unpaid invoices**: Verifies all unpaid invoices are listed in date order
3. **No unpaid invoices**: Verifies no reminder is added when all invoices are paid
4. **Unpaid invoices with messages**: Verifies both reminder and messages are included
5. **Client with no invoices**: Verifies no reminder for new clients
6. **Save and reload**: Verifies reminder isn't duplicated on reload

All 40 unit tests pass, including the 6 new tests.

### System Tests (spec/system/invoices_spec.rb)

Added 6 system tests in the "Creating a new invoice" describe block:

1. **Single unpaid invoice reminder**: Tests reminder appears in the rich text editor
2. **Multiple unpaid invoices reminder**: Tests all unpaid invoices appear
3. **No reminder when paid**: Tests no reminder when invoices are paid
4. **Reminder with messages**: Tests both reminder and messages appear together
5. **User can edit reminder**: Tests that users can modify or remove the reminder text
6. **Custom text without reminder**: Tests creating invoice with custom text (no reminder)

## Edge Cases Handled

- New records only (via `after_initialize` callback with `if: :new_record?`)
- Excludes the current invoice being created from unpaid check
- Handles nil client gracefully
- Handles empty message lists
- Handles empty unpaid invoice lists
- Date formatting uses British format (DD/MM/YYYY)
- Multiple invoices are ordered by date chronologically

## Usage Example

```ruby
# Client has an unpaid invoice
client = Client.find(1)
unpaid_invoice = Invoice.create(client: client, status: :sent, date: Date.new(2025, 6, 1))

# Create new invoice - reminder is automatically added
new_invoice = Invoice.new(client: client)
puts new_invoice.text.to_plain_text
# => "REMINDER: Invoice #123 dated 01/06/2025 remains unpaid."

# User can modify or remove the text before saving
new_invoice.text = "Custom invoice text"
new_invoice.save!
```

## Benefits

1. **Improved cash flow**: Reminds clients of outstanding invoices
2. **User flexibility**: Users can edit or remove reminders as needed
3. **Automated workflow**: No manual checking for unpaid invoices required
4. **Clear communication**: Formatted reminder is professional and clear
5. **Non-intrusive**: Only appears in draft, not automatically sent

## Files Modified

- `app/models/invoice.rb` - Added unpaid invoice reminder logic
- `spec/models/invoice_spec.rb` - Added 6 unit tests
- `spec/system/invoices_spec.rb` - Added 6 system tests

## Status

✅ Implementation complete
✅ Unit tests passing (40/40)
⏳ System tests created (require JavaScript/browser testing environment)

