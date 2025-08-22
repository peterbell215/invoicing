require 'rails_helper'

describe 'ClientSession' do
  describe '#destroyable' do
    shared_examples_for 'not destroyable' do |status|
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice_with_client_sessions) }

      before do
        invoice.update!(status: status)
      end

      specify { expect(client_session.destroyable?).to be_falsey }

      it 'is not possible to destroy a ClientSession that has been already invoiced' do
        expect { client_session.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end

    context 'when no invoice has been associated with the client session' do
      subject(:client_session) { create :client_session, client: client }
      let(:client) { create(:client) }

      specify { expect(client_session.destroyable?).to be_truthy }
      specify { expect { client_session.destroy! }.not_to raise_error }
    end

    context 'when the invoice has not yet been sent' do
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice_with_client_sessions, status: :created) }

      specify { expect(client_session.destroyable?).to be_truthy }
    end

    context 'when the invoice has been sent' do
      it_behaves_like 'not destroyable', :sent
    end

    context 'when the invoice has not been paid' do
      it_behaves_like 'not destroyable', :paid
    end
  end

  describe '#fee' do
    subject(:client_session) { FactoryBot.create(:client_session, units: 1.5) }

    it 'calculates the correct fee based on unit rate and units' do
      expect(client_session.fee).to eq(Money.new(9000)) # 1.5 hours at £60/hour = £90.00
    end
  end

  describe '#updatable' do
    context 'when no invoice has been associated with the client session' do
      subject(:client_session) { create(:client_session, client: client) }
      let(:client) { create(:client) }

      it 'can be updated' do
        original_date = client_session.session_date
        original_units = client_session.units
        new_date = Date.current + 1.day
        new_units = original_units + 2

        # Update the session
        client_session.session_date = new_date
        client_session.units = new_units

        expect { client_session.save! }.not_to raise_error

        # Verify the values have changed
        client_session.reload
        expect(client_session.session_date).to eq(new_date)
        expect(client_session.units).to eq(new_units)
      end
    end

    context 'when the invoice is in created state' do
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice_with_client_sessions) }

      it 'can be updated' do
        original_date = client_session.session_date
        original_units = client_session.units
        new_date = Date.current + 1.day
        new_units = original_units + 2

        # Update the session
        client_session.session_date = new_date
        client_session.units = new_units

        expect { client_session.save! }.not_to raise_error

        # Verify the values have changed
        client_session.reload
        expect(client_session.session_date).to eq(new_date)
        expect(client_session.units).to eq(new_units)
      end
    end

    shared_examples_for 'not updatable' do |status|
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice_with_client_sessions) }

      before do
        invoice.update_attribute(:status, status)
      end

      it 'cannot be updated when invoice has been sent or paid' do
        original_date = client_session.session_date
        original_units = client_session.units

        # Attempt to update the session should raise an exception
        client_session.session_date = Date.current + 1.day
        client_session.units = original_units + 1

        expect { client_session.save! }.to raise_error(ActiveRecord::RecordNotSaved)
        expect(client_session.errors.messages[:base].first).to eq("Cannot update once invoice sent or paid")

        # Verify the values haven't changed
        client_session.reload
        expect(client_session.session_date).to eq(original_date)
        expect(client_session.units).to eq(original_units)
      end

      it 'raises exception when using update! method' do
        expect { client_session.update!(units: 5.0) }.to raise_error(ActiveRecord::RecordNotSaved)
        expect(client_session.errors.messages[:base].first).to eq("Cannot update once invoice sent or paid")
      end
    end

    context 'when the invoice has been sent' do
      it_behaves_like 'not updatable', :sent
    end

    context 'when the invoice has been paid' do
      it_behaves_like 'not updatable', :paid
    end
  end

  describe 'invoice amount updates' do
    subject(:invoice) { create(:invoice_with_client_sessions) }
    let(:first_client_session) { invoice.client_sessions.first }

    context 'when invoice is created with client sessions' do
      it 'initially sets invoice amount based on client session fee' do
        expect(invoice.amount).to eq(Money.from_amount(60.0*3))
      end
    end

    context 'when invoice status is created ' do
      it 'updates invoice amount when units change' do
        first_client_session.update!(units: 4.0)

        invoice.reload
        expect(invoice.amount).to eq(Money.from_amount(60.0*4 + 60.0*2))
      end

      it 'updates invoice amount when unit_session_rate changes' do
        first_client_session.update!(unit_session_rate: Money.new(8000))

        invoice.reload
        expect(invoice.amount).to eq(Money.from_amount(80.0*1 + 60.0*2))
      end
    end
  end
end
