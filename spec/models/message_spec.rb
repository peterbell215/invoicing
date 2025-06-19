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
end
