# Credit Note Zero Amount Validation - Implementation Summary

## Date: November 16, 2025

## Overview
Added validation to prevent credit notes from having a zero amount, as a credit note with zero value has no meaningful purpose.

## Changes Made

### 1. Model Validation Added

**File**: `app/models/credit_note.rb`

Added validation to ensure amount_pence is not zero:

```ruby
validates :amount_pence, presence: true, numericality: { other_than: 0, message: "cannot be zero" }
```

This validation:
- Ensures amount_pence is present (not nil)
- Ensures amount_pence is not equal to 0
- Provides a clear error message: "Amount pence cannot be zero"

### 2. Test Added

**File**: `spec/models/credit_note_spec.rb`

Added test case in the "amount validation" section:

```ruby
it 'validates amount cannot be zero' do
  credit_note = CreditNote.new(invoice: invoice, amount: Money.new(0, 'GBP'), reason: 'Test reason')

  expect(credit_note).not_to be_valid
  expect(credit_note.errors[:amount_pence]).to include("cannot be zero")
end
```

### 3. Controller Fix

**File**: `app/controllers/credit_notes_controller.rb`

Fixed a lingering reference to `billings_path` in the destroy action:
- Changed: `redirect_to billings_path` 
- To: `redirect_to invoices_path`

## Validation Behavior

### Invalid Cases (Will be rejected):
- `amount: Money.new(0, 'GBP')` - Zero amount
- `amount: nil` - Nil amount (presence validation)
- `amount: Money.new(-100000, 'GBP')` - Exceeds invoice amount (existing validation)

### Valid Cases (Will be accepted):
- `amount: Money.new(1000, 'GBP')` - Positive amount (will be converted to negative)
- `amount: Money.new(-1000, 'GBP')` - Negative amount
- Any non-zero amount that doesn't exceed the invoice amount

## Test Results

All 35 credit note model tests pass:
```
Finished in 0.74511 seconds (files took 0.51659 seconds to load)
35 examples, 0 failures
```

The new test specifically validates:
- Zero amount is rejected
- Appropriate error message is displayed

## User-Facing Impact

When users try to create a credit note with a zero amount:
1. The form will display: "Amount pence cannot be zero"
2. The credit note will not be saved
3. Users will need to enter a valid non-zero amount

This prevents meaningless credit notes from being created and ensures data integrity.

## Related Validations

Credit notes also validate:
1. ✅ Amount cannot be zero (NEW)
2. ✅ Amount cannot exceed invoice amount
3. ✅ Invoice must be sent or paid before issuing credit note
4. ✅ Reason must be present
5. ✅ Date must be present
6. ✅ Invoice must be present

## Technical Notes

- The validation is on `amount_pence` rather than `amount` because Money gem stores the actual value in pence
- The validation message appears as "Amount pence cannot be zero" which could potentially be customized if needed
- The validation works with both positive and negative amounts (they're both converted to negative by the `ensure_negative_amount` callback)

