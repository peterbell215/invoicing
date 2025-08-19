require 'rails_helper'

describe 'ClientSession' do
  describe '#destroyable' do
    shared_examples_for 'not destroyable' do |status|
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice, status: status) }

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
      let(:invoice) { create(:invoice, status: :created) }

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
    shared_examples_for 'not updatable' do |status|
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice, status: status) }

      it 'cannot be updated when invoice has been sent or paid' do
        original_date = client_session.session_date
        original_units = client_session.units

        # Attempt to update the session should raise an exception
        client_session.session_date = Date.current + 1.day
        client_session.units = original_units + 1

        expect { client_session.save! }.to raise_error(ActiveRecord::RecordNotDestroyed, "Cannot delete once invoice sent or paid")

        # Verify the values haven't changed
        client_session.reload
        expect(client_session.session_date).to eq(original_date)
        expect(client_session.units).to eq(original_units)
      end

      it 'raises exception when using update! method' do
        expect { client_session.update!(units: 5.0) }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end

    shared_examples_for 'updatable' do |status|
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice, status: status) }

      it 'can be updated when invoice is in created state' do
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

    context 'when no invoice has been associated with the client session' do
      subject(:client_session) { create(:client_session, client: client) }
      let(:client) { create(:client) }

      it 'can be updated when not associated with any invoice' do
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

    context 'when the invoice has not yet been sent' do
      it_behaves_like 'updatable', :created
    end

    context 'when the invoice has been sent' do
      it_behaves_like 'not updatable', :sent
    end

    context 'when the invoice has been paid' do
      it_behaves_like 'not updatable', :paid
    end

    context 'updating specific fields' do
      subject(:client_session) { create(:client_session, client: client) }
      let(:client) { create(:client) }

      it 'allows updating session_date when not invoiced' do
        new_date = Date.current + 5.days
        expect { client_session.update!(session_date: new_date) }.not_to raise_error
        expect(client_session.reload.session_date).to eq(new_date)
      end

      it 'allows updating units when not invoiced' do
        new_units = 8.5
        expect { client_session.update!(units: new_units) }.not_to raise_error
        expect(client_session.reload.units).to eq(new_units)
      end
    end
  end
end
