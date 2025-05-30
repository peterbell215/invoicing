class InvoiceMailer < ApplicationMailer
  default from: 'katy@example.com'

  def invoice_email(invoice)
    @invoice = invoice
    @client = invoice.client

    # Attach the PDF if it exists
    if @invoice.pdf.attached?
      attachments["invoice_#{@invoice.id}.pdf"] = @invoice.pdf.download
    end

    mail(
      to: @client.email,
      subject: "Invoice ##{@invoice.id} from Katy's Services"
    )
  end
end
