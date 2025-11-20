require 'rails_helper'

RSpec.describe CreditNoteMailer, type: :mailer do
  describe '#credit_note_email' do
    subject(:mail) { CreditNoteMailer.credit_note_email(credit_note) }

    let(:credit_note) { create(:credit_note, invoice: invoice) }
    let(:invoice) { create(:invoice_with_client_sessions).tap { |invoice| invoice.update!(status: :sent) } }

    it 'renders the subject' do
      expect(mail.subject).to match(/Credit Note #\d+ for Invoice #\d+/)
    end

    it 'sends to the correct recipient' do
      expect(mail.to).to eq([credit_note.invoice.client.email])
    end

    it 'includes the credit note ID in the body' do
      expect(mail.body.encoded).to match("Credit Note ##{credit_note.id}")
    end

    it 'includes the client name' do
      expect(mail.body.encoded).to include(credit_note.invoice.client.name)
    end

    it 'includes the invoice ID' do
      expect(mail.body.encoded).to include("Invoice ##{invoice.id}")
    end

    it 'includes the amount' do
      # Amount is displayed with currency symbol (may be encoded in quoted-printable)
      expect(mail.body.encoded).to match(/-?\d+\.\d{2}/)
    end

    it 'includes the reason' do
      expect(mail.body.encoded).to include(credit_note.reason)
    end

    it 'includes organization details' do
      expect(mail.body.encoded).to include(Rails.application.credentials.org_details[:name])
      expect(mail.body.encoded).to include(Rails.application.credentials.org_details[:email])
    end

    it 'renders both HTML and text parts' do
      expect(mail.html_part.body.encoded).to include(credit_note.invoice.client.name)
      expect(mail.text_part.body.encoded).to include(credit_note.invoice.client.name)
    end

    context 'when PDF is attached' do
      before do
        # Create a mock PDF file
        pdf_content = 'Mock PDF content'
        credit_note.pdf.attach(
          io: StringIO.new(pdf_content),
          filename: "credit_note_#{credit_note.id}.pdf",
          content_type: 'application/pdf'
        )
      end

      it 'includes the PDF attachment' do
        expect(mail.attachments.size).to eq(1)
        expect(mail.attachments.first.filename).to match(/credit_note.*\.pdf/)
        expect(mail.attachments.first.content_type).to include('application/pdf')
      end
    end
  end
end
