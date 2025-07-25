require 'rails_helper'

RSpec.describe Invoice do
  include ActiveSupport::Testing::TimeHelpers

  describe 'FactoryBot' do
    subject(:invoice) { create(:invoice) }

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
end
