# Credit Note Send Functionality - Implementation Summary

## Date: November 16, 2025

## Overview
Replicated the invoice email and PDF functionality for credit notes, allowing credit notes to be sent to clients with PDF attachments via email, matching the existing invoice send functionality.

## Investigation - Invoice Send Implementation

### Invoice Send Flow:
1. **Controller** (`InvoicesController#send_invoice`):
   - Checks if PDF is already attached
   - If not, generates PDF from show page using `FerrumPdf.render_pdf`
   - Attaches PDF to invoice using Active Storage
   - Sends email via `InvoiceMailer.invoice_email(@invoice).deliver_now`
   - Marks invoice as sent: `@invoice.sent!`

2. **Mailer** (`InvoiceMailer`):
   - Receives invoice object
   - Attaches PDF from Active Storage if exists
   - Sends email to client with invoice details

3. **Email Views**:
   - HTML version: `invoice_mailer/invoice_email.html.erb`
   - Text version: `invoice_mailer/invoice_email.text.erb`
   - Includes payment details, amount, and professional formatting

## Implementation for Credit Notes

### Files Created

#### 1. Credit Note Mailer (`app/mailers/credit_note_mailer.rb`)

```ruby
class CreditNoteMailer < ApplicationMailer
  default from: 'katy@example.com'

  def credit_note_email(credit_note)
    @credit_note = credit_note
    @invoice = credit_note.invoice
    @client = credit_note.client

    # Attach the PDF if it exists
    if @credit_note.pdf.attached?
      attachments["credit_note_#{@credit_note.id}.pdf"] = @credit_note.pdf.download
    end

    mail(
      to: @client.email,
      subject: "Credit Note ##{@credit_note.id} for Invoice ##{@invoice.id} from Katy's Services"
    )
  end
end
```

**Features**:
- Uses delegation to access client through invoice
- Attaches PDF if already generated
- Subject line includes both credit note and invoice numbers
- Clear identification as a credit note, not invoice

#### 2. HTML Email View (`app/views/credit_note_mailer/credit_note_email.html.erb`)

```erb
<h1>Credit Note #<%= @credit_note.id %> from Katy's Services</h1>

<p>Dear <%= @client.name %>,</p>

<p>Please find attached your credit note #<%= @credit_note.id %> for Invoice #<%= @invoice.id %> in the amount of <%= @credit_note.amount.format %>.</p>

<p><strong>Reason:</strong> <%= @credit_note.reason %></p>

<p>This credit will be applied to your account or refunded according to our standard procedures.</p>

<p>If you have any questions about this credit note, please don't hesitate to contact us.</p>

<p>
Best regards,<br>
Katy Smith<br>
Katy's Services<br>
Phone: 020 1234 5678<br>
Email: katy@example.com
</p>
```

**Features**:
- Displays credit note and invoice numbers
- Shows the negative amount (credit)
- Includes the reason for the credit note
- Professional tone appropriate for credits
- Clear next steps for client

#### 3. Text Email View (`app/views/credit_note_mailer/credit_note_email.text.erb`)

Plain text version for email clients that don't support HTML.

### Files Modified

#### Updated: `app/controllers/credit_notes_controller.rb`

**Before** (incomplete implementation):
```ruby
def send_credit_note
  @credit_note = CreditNote.find(params[:id])
  
  if @credit_note.created?
    @credit_note.sent!
    redirect_to @credit_note, notice: "Credit note was successfully sent."
  else
    redirect_to @credit_note, alert: "Credit note has already been sent."
  end
end
```

**After** (complete implementation):
```ruby
def send_credit_note
  @credit_note = CreditNote.find(params[:id])
  
  unless @credit_note.created?
    redirect_to @credit_note, alert: "Credit note has already been sent."
    return
  end

  # Check if PDF is already attached
  unless @credit_note.pdf.attached?
    # Generate PDF using Grover
    pdf_content = generate_credit_note_pdf

    # Attach the PDF to the credit note
    @credit_note.pdf.attach(
      io: StringIO.new(pdf_content),
      filename: "credit_note_#{@credit_note.id}.pdf",
      content_type: "application/pdf"
    )
  end

  # Send the email
  CreditNoteMailer.credit_note_email(@credit_note).deliver_now

  # Mark the credit note as sent
  @credit_note.sent!

  redirect_to @credit_note, notice: "Credit note was successfully sent."
end

private

def generate_credit_note_pdf
  # Get the HTML of the credit note show page
  html = render_to_string template: "credit_notes/show", layout: "pdf", locals: { credit_note: @credit_note }

  # Convert to PDF using Ferrum_pdf
  FerrumPdf.render_pdf(html: html)
end
```

**New Features**:
- PDF generation from credit note show page
- PDF attachment to credit note using Active Storage
- Email delivery with PDF attachment
- Proper status transition to 'sent'
- Mirrors invoice implementation exactly

## Feature Comparison

| Feature | Invoice | Credit Note | Status |
|---------|---------|-------------|--------|
| PDF Generation | ✅ | ✅ | Implemented |
| PDF Attachment (Active Storage) | ✅ | ✅ | Implemented |
| Email Sending | ✅ | ✅ | Implemented |
| HTML Email Template | ✅ | ✅ | Implemented |
| Text Email Template | ✅ | ✅ | Implemented |
| Status Update on Send | ✅ (sent!) | ✅ (sent!) | Implemented |
| Prevent Re-sending | ✅ | ✅ | Implemented |
| Professional Formatting | ✅ | ✅ | Implemented |

## Complete Flow Diagram

```
User clicks "Send" on Credit Note
         ↓
CreditNotesController#send_credit_note
         ↓
Check if already sent → Yes → Show error
         ↓ No
Check if PDF attached → Yes → Skip PDF generation
         ↓ No
Generate PDF from show page
  - Renders credit_notes/show with PDF layout
  - Uses FerrumPdf.render_pdf(html)
         ↓
Attach PDF to credit_note
  - Uses Active Storage
  - Filename: "credit_note_{id}.pdf"
         ↓
Send Email
  - CreditNoteMailer.credit_note_email(@credit_note)
  - Attaches PDF from Active Storage
  - Sends to client.email
         ↓
Mark as Sent
  - @credit_note.sent!
  - Changes status from created → sent
         ↓
Redirect with success message
```

## Email Content Details

### Subject Line
```
Credit Note #{credit_note_id} for Invoice #{invoice_id} from Katy's Services
```

### Email Body Includes:
- Personalized greeting with client name
- Credit note number and invoice reference
- Amount of credit (formatted with currency)
- Reason for credit note
- Explanation of next steps
- Contact information
- Professional signature

### PDF Attachment
- Filename: `credit_note_{id}.pdf`
- Generated from: `credit_notes/show` view with PDF layout
- Includes all credit note details, client info, and formatting

## Technical Implementation Details

### Active Storage Integration
Credit notes use the same Active Storage pattern as invoices:
```ruby
has_one_attached :pdf  # Already defined in CreditNote model
```

### PDF Generation
Uses the same `FerrumPdf` gem as invoices:
```ruby
FerrumPdf.render_pdf(html: html)
```

### Email Delivery
Uses ActionMailer's `deliver_now` for immediate sending:
```ruby
CreditNoteMailer.credit_note_email(@credit_note).deliver_now
```

### Status Management
Credit notes transition from `created` → `sent`:
```ruby
@credit_note.sent!  # Updates status enum
```

## Integration with Existing Views

### Where Send Button Appears:

1. **Credit Note Show Page** (`credit_notes/show.html.erb`)
   - "Send Credit Note" button visible when status is 'created'
   - Button uses `button_to send_credit_note_credit_note_path`

2. **Invoices Index - Credit Note Row** (`invoices/_credit_note_row.html.erb`)
   - "Send" button in action column for created credit notes
   - Integrated with send-confirmation dialog

### Route Configuration
Already configured in `config/routes.rb`:
```ruby
resources :credit_notes, only: [:show, :edit, :update, :destroy] do
  member do
    post :send_credit_note  # ← This route
  end
end
```

## Testing Verification

### Manual Testing Steps:

1. **Create a Credit Note**:
   - Go to an invoice
   - Click "Issue Credit Note"
   - Fill in amount and reason
   - Save

2. **Send the Credit Note**:
   - Click "Send Credit Note" button
   - Verify success message: "Credit note was successfully sent"
   - Check that status changes to "sent"

3. **Verify Email**:
   - Check development email folder: `tmp/my_mails/`
   - Verify email contains credit note details
   - Verify PDF is attached
   - Check both HTML and text versions

4. **Verify PDF Attachment**:
   - Download PDF from email
   - Verify it matches the credit note show page
   - Check all details are correct

5. **Verify Status Protection**:
   - Try clicking "Send" again on a sent credit note
   - Should see: "Credit note has already been sent"
   - Button should not be visible on sent credit notes

### Automated Testing Recommendations:

1. **Mailer Spec** (`spec/mailers/credit_note_mailer_spec.rb`):
   - Test email is sent to correct recipient
   - Test subject line format
   - Test PDF attachment presence
   - Test email body content

2. **Controller Spec** (`spec/controllers/credit_notes_controller_spec.rb`):
   - Test PDF generation
   - Test email delivery
   - Test status transition
   - Test duplicate send prevention

3. **System Spec** (`spec/system/credit_notes_spec.rb`):
   - Test full send workflow
   - Verify email in test inbox
   - Check status changes

## Benefits Achieved

1. **Feature Parity**: Credit notes now have same email/PDF functionality as invoices
2. **Professional Communication**: Clients receive properly formatted credit notes
3. **Audit Trail**: PDF attachment creates permanent record
4. **Status Tracking**: Clear distinction between created and sent credit notes
5. **Consistent UX**: Same workflow as invoice sending
6. **Reusable Pattern**: Email templates follow established conventions

## Files Summary

### Created:
- `app/mailers/credit_note_mailer.rb`
- `app/views/credit_note_mailer/credit_note_email.html.erb`
- `app/views/credit_note_mailer/credit_note_email.text.erb`

### Modified:
- `app/controllers/credit_notes_controller.rb` (enhanced `send_credit_note` method, added `generate_credit_note_pdf` method)

### Dependencies (Already Existing):
- `FerrumPdf` gem for PDF generation
- Active Storage for PDF attachments
- ActionMailer for email delivery
- CreditNote model with `has_one_attached :pdf`

## Next Steps for Production

1. **Update Email Configuration**:
   - Change `default from:` address to actual business email
   - Configure SMTP settings for production
   - Set up email delivery service (SendGrid, AWS SES, etc.)

2. **Customize Email Content**:
   - Update company name, address, phone, etc.
   - Adjust payment/refund procedures text
   - Add company logo if desired

3. **Add Email Tracking** (Optional):
   - Track when emails are opened
   - Track PDF downloads
   - Integration with email service provider

4. **Create Mailer Specs**:
   - Test email delivery
   - Test PDF attachments
   - Test content rendering

The implementation is complete and ready for testing!

