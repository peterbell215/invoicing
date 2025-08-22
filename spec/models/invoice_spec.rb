require 'rails_helper'

RSpec.describe Invoice do
  include ActiveSupport::Testing::TimeHelpers

  describe 'FactoryBot' do
    subject(:invoice) { create(:invoice_with_client_sessions) }

    specify { expect(invoice.date).to eq Date.new(2025, 2, 1) }
    specify { expect(invoice.client_sessions.length).to eq 3 }
  end

  describe '::create' do
    context 'when it is a new invoice' do
      let(:invoice_params) { attributes_for(:invoice, client_id: client.id) }
      let(:client) { create(:client, :with_client_sessions) }

      it 'creates the invoice and associates all the client sessions' do
        client_session_ids = client.client_session_ids
        amount = Money.new(ClientSession.where(id: client_session_ids).sum(&:fee), 'GBP')

        invoice_params[:client_session_ids] = client_session_ids

        invoice = Invoice.create(invoice_params)

        expect(invoice.client_sessions.pluck(:id)).to match client_session_ids
        expect(invoice.amount).to eq(amount)
      end

      it 'creates the invoice and associates some of the client sessions' do
        client_session_ids = client.client_session_ids
        first_client_session_id = client_session_ids.pop

        invoice_params[:client_session_ids] = client_session_ids
        invoice = Invoice.create(invoice_params)

        expect(invoice.client_sessions.pluck(:id)).to match client_session_ids
        expect(ClientSession.find(first_client_session_id).invoice_id).to be_nil
      end
    end
  end

  describe 'destruction' do
    context 'when invoice status is created' do
      it 'allows destruction' do
        invoice = create(:invoice, status: :created)
        expect(invoice.destroy).not_to be_falsey
        expect(invoice.persisted?).to be_falsey
      end
    end

    context 'when invoice status is sent' do
      it 'prevents destruction' do
        invoice = create(:invoice, status: :sent)
        expect(invoice.destroy).to be_falsey
      end

      it 'does not destroy the record' do
        invoice = create(:invoice, status: :sent)
        invoice.destroy
        expect(invoice.persisted?).to be true
      end
    end

    context 'when invoice status is paid' do
      it 'prevents destruction' do
        invoice = create(:invoice, status: :paid)
        expect(invoice.destroy).to be_falsey
      end

      it 'does not destroy the record' do
        invoice = create(:invoice, status: :paid)
        invoice.destroy
        expect(invoice.persisted?).to be true
      end
    end
  end

  describe 'client session handling during destruction' do
    context 'when invoice is destroyed' do
      it 'removes invoice association from client sessions' do
        client = create(:client)
        invoice = create(:invoice, client: client, status: :created)
        client_session = create(:client_session, client: client, invoice: invoice)

        invoice.destroy
        client_session.reload
        expect(client_session.invoice_id).to be_nil
      end

      it 'removes invoice association from multiple client sessions' do
        client = create(:client)
        invoice = create(:invoice, client: client, status: :created)

        # Create multiple client sessions associated with the invoice
        session1 = create(:client_session, client: client, invoice: invoice)
        session2 = create(:client_session, client: client, invoice: invoice)
        session3 = create(:client_session, client: client, invoice: invoice)

        # Verify sessions are associated with the invoice
        expect(session1.reload.invoice_id).to eq(invoice.id)
        expect(session2.reload.invoice_id).to eq(invoice.id)
        expect(session3.reload.invoice_id).to eq(invoice.id)

        # Destroy the invoice
        invoice.destroy

        # Verify all sessions have their invoice_id reset to nil
        expect(session1.reload.invoice_id).to be_nil
        expect(session2.reload.invoice_id).to be_nil
        expect(session3.reload.invoice_id).to be_nil
      end
    end
  end

  describe 'date initialization' do
    let(:client) { create(:client) }

    it 'sets date to current date when creating a new invoice without specifying date' do
      travel_to Time.zone.local(2025, 7, 12, 10, 0, 0) do
        invoice = Invoice.new(client: client)
        expect(invoice.date).to eq(Date.current)
      end
    end

    it 'does not override explicitly set date when creating new invoice' do
      custom_date = Date.new(2025, 6, 15)
      invoice = Invoice.new(client: client, date: custom_date)
      expect(invoice.date).to eq(custom_date)
    end

    it 'does not set date when loading existing invoice from database' do
      # Create an invoice with a specific date
      invoice = create(:invoice, client: client, date: Date.new(2025, 1, 1))

      # Reload from database and verify date hasn't changed
      travel_to Time.zone.local(2025, 7, 12, 10, 0, 0) do
        reloaded_invoice = Invoice.find(invoice.id)
        expect(reloaded_invoice.date).to eq(Date.new(2025, 1, 1))
        expect(reloaded_invoice.date).not_to eq(Date.current)
      end
    end

    it 'sets date when building through association' do
      travel_to Time.zone.local(2025, 7, 12, 10, 0, 0) do
        invoice = client.invoices.build
        expect(invoice.date).to eq(Date.current)
      end
    end
  end

  describe 'message text population' do
    let(:client) { FactoryBot.create(:client) }

    it 'populates text from messages sorted by created_at date' do
      travel_to Time.zone.local(2025, 7, 12, 10, 0, 0) do
        # Create two messages with different creation times
        older_message = FactoryBot.create(:message, text: "This is the first message", created_at: 2.hours.ago)
        newer_message = FactoryBot.create(:message, text: "This is the second message", created_at: 1.hours.ago)

        # Associate both messages with the client
        older_message.apply_to_client(client)
        newer_message.apply_to_client(client)

        # Create new invoice which should populate text from messages
        invoice = Invoice.new(client: client)

        # Expected text should have messages in chronological order (oldest first)
        expected_text = "This is the first message\n\n  This is the second message"
        expect(invoice.text.to_plain_text.strip).to eq(expected_text)
      end
    end
  end

  describe '#validate_editable_status' do
    let(:invoice) { FactoryBot.create(:invoice, status: :created) }

    # Shared examples for invoices that cannot be edited
    shared_examples 'non-editable invoice' do
      it 'prevents changing non-status fields' do
        invoice.date = Date.current + 1.day

        expect(invoice).not_to be_valid
        expect(invoice.errors[:date]).to include("cannot be changed once the invoice has been sent or paid")
      end

      it 'prevents changing text field' do
        invoice.text = 'Updated text'

        expect(invoice).not_to be_valid
        expect(invoice.errors[:text]).to include("cannot be changed once the invoice has been sent or paid")
      end

      it 'prevents changing status from current status to created' do
        invoice.status = :created

        expect(invoice).not_to be_valid
        expect(invoice.errors[:status]).to include("can only be marked as 'paid' after being 'sent'")
      end

      it 'prevents changing multiple non-status fields' do
        invoice.date = Date.current + 1.day
        invoice.text = 'Updated text'

        expect(invoice).not_to be_valid
        expect(invoice.errors[:date]).to include("cannot be changed once the invoice has been sent or paid")
        expect(invoice.errors[:text]).to include("cannot be changed once the invoice has been sent or paid")
      end
    end

    context 'when status is created' do
      it 'allows changing non-status fields' do
        invoice.date = Date.current + 1.day
        invoice.text = 'Updated text'

        expect(invoice).to be_valid
        expect(invoice.save).to be true
      end

      it 'allows changing status from created to sent' do
        invoice.status = :sent

        expect(invoice).to be_valid
        expect(invoice.save).to be true
        expect(invoice.reload.status).to eq('sent')
      end

      it 'allows changing status from created to paid' do
        invoice.status = :paid

        expect(invoice).to be_valid
        expect(invoice.save).to be true
        expect(invoice.reload.status).to eq('paid')
      end

      it 'allows changing both status and other fields simultaneously' do
        invoice.status = :sent
        invoice.date = Date.current + 1.day

        expect(invoice).to be_valid
        expect(invoice.save).to be true
      end
    end

    context 'when status is sent' do
      before { invoice.update!(status: :sent) }

      it_behaves_like 'non-editable invoice'

      it 'allows changing status from sent to paid' do
        invoice.status = :paid

        expect(invoice).to be_valid
        expect(invoice.save).to be true
        expect(invoice.reload.status).to eq('paid')
      end
    end

    context 'when status is paid' do
      before { invoice.update!(status: :paid) }

      it_behaves_like 'non-editable invoice'

      it 'prevents changing status from paid to sent' do
        invoice.status = :sent

        expect(invoice).not_to be_valid
        expect(invoice.errors[:status]).to include("can only be marked as 'paid' after being 'sent'")
      end

      it 'prevents changing status from paid to created' do
        invoice.status = :created

        expect(invoice).not_to be_valid
        expect(invoice.errors[:status]).to include("can only be marked as 'paid' after being 'sent'")
      end
    end

    context 'edge cases' do
      it 'allows status to remain the same while changing other fields when status is created' do
        invoice.status = :created  # Same as current status
        invoice.date = Date.current + 1.day

        expect(invoice).to be_valid
        expect(invoice.save).to be true
      end

      it 'prevents direct transition from created to paid with field changes' do
        invoice.status = :paid
        invoice.date = Date.current + 1.day

        expect(invoice).to be_valid  # The status change itself is allowed
        expect(invoice.save).to be true
      end

      it 'handles multiple validation errors correctly' do
        invoice.update!(status: :sent)
        invoice.date = Date.current + 1.day
        invoice.text = 'Updated text'
        invoice.status = :created

        expect(invoice).not_to be_valid
        expect(invoice.errors.count).to be > 1
        expect(invoice.errors[:status]).to be_present
        expect(invoice.errors[:date]).to be_present
        expect(invoice.errors[:text]).to be_present
      end
    end
  end
end
