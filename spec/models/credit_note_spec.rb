require 'rails_helper'

RSpec.describe CreditNote do
  include ActiveSupport::Testing::TimeHelpers

  let(:invoice) { create(:invoice_with_client_sessions).tap { |invoice| invoice.update!(status: :sent) } }

  describe 'FactoryBot' do
    subject(:credit_note) { create(:credit_note, invoice: invoice) }

    specify { expect(credit_note.invoice).to be_present }
    specify { expect(credit_note.client).to be_present }
    specify { expect(credit_note.amount).to be_negative }
    specify { expect(credit_note.reason).to be_present }
  end

  describe '::create' do
    context 'when it is a new credit note' do
      subject(:credit_note_params) { { invoice: invoice, amount: Money.new(5000, 'GBP'), reason: 'Customer requested refund' } }

      let(:invoice) { create(:invoice_with_client_sessions).tap { |invoice| invoice.update!(status: :sent) } }

      it 'creates the credit note with negative amount' do
        credit_note = CreditNote.create(credit_note_params)

        expect(credit_note).to be_persisted
        expect(credit_note.status).to eq('created')
        expect(credit_note.amount).to be_negative
        expect(credit_note.amount.abs).to eq(Money.new(5000, 'GBP'))
      end

      it 'creates the credit note associated with the invoice' do
        credit_note = CreditNote.create(credit_note_params)

        expect(credit_note.invoice).to eq(invoice)
        expect(invoice.credit_notes).to include(credit_note)
      end

      it 'creates the credit note with the same client as the invoice' do
        credit_note = CreditNote.create(credit_note_params)
        expect(credit_note.client).to eq(invoice.client)
      end

      context 'when the invoice has a payee' do
        let(:invoice) { create(:invoice_with_client_sessions, payee: payee).tap { |inv| inv.update!(status: :sent) } }
        let(:payee) { create(:payee) }

        it 'sets the payee from the invoice' do
          credit_note = CreditNote.create(credit_note_params)

          expect(credit_note.payee).to eq(payee)
          expect(credit_note.payee).to eq(invoice.payee)
        end
      end
    end
  end

  describe 'validations' do
    describe 'reason presence' do
      it 'requires a reason' do
        credit_note = CreditNote.new(invoice: invoice, amount: Money.new(5000, 'GBP'))

        expect(credit_note).not_to be_valid
        expect(credit_note.errors[:reason]).to include("can't be blank")
      end
    end

    describe 'amount validation' do
      it 'validates amount cannot be zero' do
        credit_note = CreditNote.new(invoice: invoice, amount: Money.new(0, 'GBP'), reason: 'Test reason')

        expect(credit_note).not_to be_valid
        expect(credit_note.errors[:amount_pence]).to include("cannot be zero")
      end

      it 'validates amount does not exceed invoice amount' do
        invoice_amount = invoice.amount
        excessive_amount = Money.new(invoice_amount.cents + 10000, 'GBP')

        credit_note = CreditNote.new(invoice: invoice, amount: excessive_amount, reason: 'Test reason')

        expect(credit_note).not_to be_valid
        expect(credit_note.errors[:amount]).to include("cannot exceed invoice amount of #{invoice_amount.format}")
      end

      it 'allows amount equal to invoice amount' do
        credit_note = CreditNote.new(invoice: invoice, amount: invoice.amount, reason: 'Full refund')

        expect(credit_note).to be_valid
      end

      it 'allows amount less than invoice amount' do
        credit_note = CreditNote.new(invoice: invoice, amount: Money.new(invoice.amount.cents / 2, 'GBP'), reason: 'Partial refund')

        expect(credit_note).to be_valid
      end
    end

    describe 'invoice status validation' do
      it 'prevents creating credit note for created invoice' do
        created_invoice = create(:invoice, status: :created)
        credit_note = CreditNote.new(invoice: created_invoice, amount: Money.new(5000, 'GBP'), reason: 'Test reason')

        expect(credit_note).not_to be_valid
        expect(credit_note.errors[:invoice]).to include("must be sent or paid before issuing a credit note")
      end

      it 'allows creating credit note for paid invoice' do
        paid_invoice = create(:invoice_with_client_sessions).tap { |inv| inv.update!(status: :paid) }
        credit_note = CreditNote.new(invoice: paid_invoice, amount: Money.new(5000, 'GBP'), reason: 'Test reason')

        expect(credit_note).to be_valid
      end
    end
  end

  describe 'destruction' do
    subject(:credit_note) { create(:credit_note, invoice: invoice) }

    context 'when credit note status is created' do
      it 'allows destruction' do
        expect(credit_note.destroy).not_to be_falsey
        expect(credit_note.persisted?).to be_falsey
      end
    end

    context 'when credit note status is sent' do
      before { credit_note.update!(status: :sent) }

      it 'prevents destruction' do
        expect(credit_note.destroy).to be_falsey
      end

      it 'does not destroy the record' do
        credit_note.destroy
        expect(credit_note.persisted?).to be true
      end
    end
  end

  describe 'date initialization' do
    it 'sets date to current date when creating a new credit note without specifying date' do
      travel_to Time.zone.local(2025, 11, 16, 10, 0, 0) do
        credit_note = CreditNote.new(invoice: invoice, amount: Money.new(5000, 'GBP'), reason: 'Test reason')
        expect(credit_note.date).to eq(Date.current)
      end
    end

    it 'does not override explicitly set date when creating new credit note' do
      custom_date = Date.new(2025, 10, 15)
      credit_note = CreditNote.new(invoice: invoice, amount: Money.new(5000, 'GBP'), reason: 'Test reason', date: custom_date)
      expect(credit_note.date).to eq(custom_date)
    end

    it 'does not set date when loading existing credit note from database' do
      credit_note = create(:credit_note, invoice_param: invoice, date: Date.new(2025, 1, 1))

      travel_to Time.zone.local(2025, 11, 16, 10, 0, 0) do
        reloaded_credit_note = CreditNote.find(credit_note.id)
        expect(reloaded_credit_note.date).to eq(Date.new(2025, 1, 1))
        expect(reloaded_credit_note.date).not_to eq(Date.current)
      end
    end
  end

  describe 'amount handling' do
    it 'automatically converts positive amount to negative' do
      credit_note = CreditNote.create(invoice: invoice, amount: Money.new(5000, 'GBP'), reason: 'Test reason')

      expect(credit_note.amount).to be_negative
      expect(credit_note.amount.abs.cents).to eq(5000)
    end

    it 'keeps negative amount as negative' do
      credit_note = CreditNote.create(invoice: invoice, amount: Money.new(-5000, 'GBP'), reason: 'Test reason')

      expect(credit_note.amount).to be_negative
      expect(credit_note.amount_pence).to eq(-5000)
    end

    it 'stores amount as negative in database' do
      credit_note = CreditNote.create(invoice: invoice, amount: Money.new(5000, 'GBP'), reason: 'Test reason')

      credit_note.reload
      expect(credit_note.amount).to be_negative
    end
  end

  describe '#validate_editable_status' do
    subject(:credit_note) { create(:credit_note, invoice: invoice) }

    context 'when status is created' do
      it 'allows changing non-status fields' do
        credit_note.date = Date.current + 1.day
        credit_note.reason = 'Updated reason'
        credit_note.amount = Money.new(3000, 'GBP')

        expect(credit_note).to be_valid
        expect(credit_note.save).to be true
      end

      it 'allows changing status from created to sent' do
        credit_note.status = :sent

        expect(credit_note).to be_valid
        expect(credit_note.save).to be true
        expect(credit_note.reload.status).to eq('sent')
      end

      it 'allows changing both status and other fields simultaneously' do
        credit_note.status = :sent
        credit_note.date = Date.current + 1.day

        expect(credit_note).to be_valid
        expect(credit_note.save).to be true
      end
    end

    context 'when status is sent' do
      before { credit_note.update!(status: :sent) }

      it 'prevents changing status back to created' do
        credit_note.status = :created

        expect(credit_note).not_to be_valid
        expect(credit_note.errors[:status]).to be_present
      end

      it 'prevents changing multiple non-status fields' do
        credit_note.date = Date.current + 1.day
        credit_note.reason = 'Updated reason'
        credit_note.amount = Money.new(-3000, 'GBP')

        expect(credit_note).not_to be_valid
        expect(credit_note.errors[:date]).to include("cannot be changed once the credit note has been sent or applied")
        expect(credit_note.errors[:reason]).to include("cannot be changed once the credit note has been sent or applied")
        expect(credit_note.errors[:amount_pence]).to include("cannot be changed once the credit note has been sent or applied")
      end
    end
  end

  describe 'status transitions' do
    let(:credit_note) { create(:credit_note, invoice: invoice) }

    it 'allows transition from created to sent' do
      credit_note.status = :sent
      expect(credit_note).to be_valid
      expect(credit_note.save).to be true
    end

    it 'prevents transition from sent to created' do
      credit_note.update!(status: :sent)
      credit_note.status = :created
      expect(credit_note).not_to be_valid
      expect(credit_note.errors[:status]).to be_present
    end
  end

  describe 'invoice association' do
    subject!(:credit_note) { create(:credit_note, invoice: invoice) }

    it 'belongs to an invoice' do
      expect(credit_note.invoice).to eq(invoice)
    end

    it 'is included in invoice credit_notes collection' do
      expect(invoice.credit_notes).to include(credit_note)
    end

    it 'can have multiple credit notes for one invoice' do
      credit_note2 = create(:credit_note, invoice: invoice, amount: Money.new(-2000, 'GBP'))

      expect(invoice.credit_notes.count).to eq(2)
      expect(invoice.credit_notes).to include(credit_note, credit_note2)
    end
  end

  describe '#summary' do
    let(:credit_note) { create(:credit_note, invoice: invoice) }

    it 'returns a summary with credit note and invoice IDs' do
      expected_summary = "Credit Note ##{credit_note.id} for Invoice ##{credit_note.invoice_id}"
      expect(credit_note.summary).to eq(expected_summary)
    end
  end
end

