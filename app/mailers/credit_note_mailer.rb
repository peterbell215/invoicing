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

