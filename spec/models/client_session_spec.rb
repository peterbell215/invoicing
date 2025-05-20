require 'rails_helper'

describe 'ClientSession' do
  describe '#destroyable' do
    shared_examples_for 'not destroyable' do |status|
      subject(:client_session) { invoice.client_sessions.first }
      let(:invoice) { create(:invoice, :client_with_sessions, status: status) }

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
      let(:invoice) { create(:invoice, :client_with_sessions, status: :created) }

      specify { expect(client_session.destroyable?).to be_truthy }
    end

    context 'when the invoice has been sent' do
      it_behaves_like 'not destroyable', :sent
    end

    context 'when the invoice has not been paid' do
      it_behaves_like 'not destroyable', :paid
    end
  end
end
