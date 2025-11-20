require 'rails_helper'

RSpec.describe InvoiceMailer, type: :mailer do
  describe '#invoice_email' do
    subject(:mail) { InvoiceMailer.invoice_email(invoice) }

    let(:invoice) { create(:invoice_with_client_sessions).tap { |inv| inv.update!(status: :sent) } }

    it 'renders the subject' do
      expect(mail.subject).to match(/Invoice #\d+ from/)
    end

    it 'sends to the correct recipient' do
      expect(mail.to).to eq([invoice.client.email])
    end

    it 'includes the invoice ID in the body' do
      expect(mail.body.encoded).to match("Invoice ##{invoice.id}")
    end

    it 'includes the client name' do
      expect(mail.body.encoded).to include(invoice.client.name)
    end

    it 'includes the amount' do
      # Amount is displayed with currency symbol (may be encoded in quoted-printable)
      expect(mail.body.encoded).to match(/£?\d+\.\d{2}/)
    end

    it 'includes organization details' do
      expect(mail.body.encoded).to include(Rails.application.credentials.org_details[:name])
      expect(mail.body.encoded).to include(Rails.application.credentials.org_details[:email])
    end

    it 'renders both HTML and text parts' do
      expect(mail.html_part.body.encoded).to include(invoice.client.name)
      expect(mail.text_part.body.encoded).to include(invoice.client.name)
    end

    context 'when PDF is attached' do
      before do
        # Create a mock PDF file
        pdf_content = 'Mock PDF content'
        invoice.pdf.attach(
          io: StringIO.new(pdf_content),
          filename: "invoice_#{invoice.id}.pdf",
          content_type: 'application/pdf'
        )
      end

      it 'includes the PDF attachment' do
        expect(mail.attachments.size).to eq(1)
        expect(mail.attachments.first.filename).to match(/invoice.*\.pdf/)
        expect(mail.attachments.first.content_type).to include('application/pdf')
      end
    end
  end
end

