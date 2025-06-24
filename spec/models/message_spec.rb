require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'date filtering with #current scope' do
    # Today's date for reference in tests
    let(:today) { Date.new(2025, 6, 19) }

    before do
      # Mock the current date to ensure consistent test results
      allow(Date).to receive(:today).and_return(today)
    end

    context 'with from_date' do
      it 'includes messages where from_date is today' do
        message = create(:message, from_date: today, until_date: nil)
        expect(Message.current).to include(message)
      end

      it 'includes messages where from_date is in the past' do
        message = create(:message, from_date: today - 5.days, until_date: nil)
        expect(Message.current).to include(message)
      end

      it 'excludes messages where from_date is in the future' do
        message = create(:message, from_date: today + 1.day, until_date: nil)
        expect(Message.current).not_to include(message)
      end
    end

    context 'with until_date' do
      it 'includes messages where until_date is today' do
        message = create(:message, from_date: nil, until_date: today)
        expect(Message.current).to include(message)
      end

      it 'includes messages where until_date is in the future' do
        message = create(:message, from_date: nil, until_date: today + 5.days)
        expect(Message.current).to include(message)
      end

      it 'excludes messages where until_date is in the past' do
        message = create(:message, from_date: nil, until_date: today - 1.day)
        expect(Message.current).not_to include(message)
      end
    end

    context 'with both from_date and until_date' do
      it 'includes messages within the date range including today' do
        message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        expect(Message.current).to include(message)
      end

      it 'includes messages where today is the start date' do
        message = create(:message, from_date: today, until_date: today + 5.days)
        expect(Message.current).to include(message)
      end

      it 'includes messages where today is the end date' do
        message = create(:message, from_date: today - 5.days, until_date: today)
        expect(Message.current).to include(message)
      end

      it 'excludes messages where the date range is entirely in the future' do
        message = create(:message, from_date: today + 1.day, until_date: today + 10.days)
        expect(Message.current).not_to include(message)
      end

      it 'excludes messages where the date range is entirely in the past' do
        message = create(:message, from_date: today - 10.days, until_date: today - 1.day)
        expect(Message.current).not_to include(message)
      end
    end

    context 'with nil dates' do
      it 'includes messages with both from_date and until_date as nil' do
        message = create(:message, from_date: nil, until_date: nil)
        expect(Message.current).to include(message)
      end
    end

    context 'with multiple messages' do
      it 'returns only current messages when mixed with non-current ones' do
        current_message1 = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        current_message2 = create(:message, from_date: nil, until_date: nil)
        current_message3 = create(:message, from_date: today, until_date: nil)

        past_message = create(:message, from_date: today - 10.days, until_date: today - 1.day)
        future_message = create(:message, from_date: today + 1.day, until_date: today + 10.days)

        current_messages = Message.current

        expect(current_messages).to include(current_message1)
        expect(current_messages).to include(current_message2)
        expect(current_messages).to include(current_message3)
        expect(current_messages).not_to include(past_message)
        expect(current_messages).not_to include(future_message)
        expect(current_messages.count).to eq(3)
      end
    end
  end

  describe 'client associations' do
    subject(:message) { create(:message) }
    let(:clients) { create_list(:client_with_random_name, 3) }

    describe '#all_clients?' do
      it 'returns true when the message applies to all clients' do
        message.messages_for_clients.create(client_id: nil)
        expect(message.all_clients?).to be true
      end

      it 'returns false when the message does not apply to all clients' do
        expect(message.all_clients?).to be false
      end
    end

    describe '#clients=' do
      it 'creates a record with nil client_id when set to all' do
        message.clients = "all"
        expect(message.messages_for_clients.exists?(client_id: nil)).to be true
        expect(message.messages_for_clients.where.not(client_id: nil).count).to be_zero
      end

      it 'allows a subset to be set for the message' do
        message.client_ids = clients.first(2).map(&:id)
        message.save!

        message.reload
        expect(message.clients.count).to eq(2)
        expect(message.clients.first.id).to eq(clients.first.id)
        expect(message.clients.second.id).to eq(clients.second.id)
      end

      it "allows the subset to be changed, adding some and removing others" do
        message.client_ids = clients.first(2).map(&:id)
        message.save!

        message.client_ids = clients.last(2).map(&:id)
        message.save!

        message.reload
        expect(message.clients.count).to eq(2)
        expect(message.clients.first.id).to eq(clients.second.id)
        expect(message.clients.second.id).to eq(clients.third.id)
      end

      it 'removes the all-clients record when set to a specific subset' do
        message.client_ids = "all"
        message.save!

        message.client_ids = clients.first(2).map(&:id)
        message.save!

        expect(message.messages_for_clients.exists?(client_id: nil)).to be false
      end
    end

    describe '#apply_to_client' do
      it 'creates an association with the specified client' do
        message.apply_to_client(clients.first)

        expect(message.clients).to include(clients.first)
      end

      it 'does not create duplicate client associations' do
        message.apply_to_client(clients.first)
        message.apply_to_client(clients.first)

        expect(message.clients.count).to eq(1)
      end
    end
  end
end
