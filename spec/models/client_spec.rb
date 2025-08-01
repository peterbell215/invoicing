require 'rails_helper'

describe Client do
  describe 'FactoryBot' do
    context 'when FactoryBot builds a client' do
      subject(:test_client) { create(:client) }

      specify { expect(test_client.name).to eq('Test One') }
    end

    context 'when Factorybot builds a client with fees' do
      subject(:test_client) { create(:client, :with_fees) }

      specify { expect(test_client.fees.length).to eq 3 }
      specify { expect(test_client.fees[0].from).to eq Date.new(2022, 12, 1) }
      specify { expect(test_client.fees[0].to + 1.day).to eq test_client.fees[1].from }
    end

    context 'when FactoryBot builds a client with client sessions' do
      subject(:test_client) { create(:client, :with_client_sessions) }

      specify { expect(test_client.client_sessions.length).to eq 4 }
      specify { expect(test_client.client_sessions[0].session_date).to eq DateTime.new(2025, 1, 10) }
      specify { expect(test_client.client_sessions[0].duration).to eq 60 }
      specify { expect(test_client.client_sessions[0].session_date + 1.week).to eq test_client.client_sessions[1].session_date }
    end
  end

  describe 'validations' do
    %i[name email address1 town postcode].each do |field|
      it "flags an empty #{field}" do
        test_client = build(:client, field => nil)
        expect(test_client).not_to be_valid
      end
    end

    example_group 'postcode' do
      specify { expect(build(:client, postcode: 'CB1 1TT')).to be_valid }
      specify { expect(build(:client, postcode: 'cb1 1tt')).to be_valid }
      specify { expect(build(:client, postcode: 'cb999 111')).not_to be_valid }
    end

    it 'is not possible to leave #new_rate blank if #new_rate_from is set' do
      client = build(:client)
      client.new_rate = nil
      expect(client).not_to be_valid
      expect(client.errors[:new_rate]).to include('cannot be blank if New Rate From is set')
    end
  end

  describe '#current_rate' do
    context 'when a new record is built with a nil value for hourly_charge' do
      subject(:test_client) { build(:client) }

      it 'autofills the fee.' do
        expect(test_client.current_rate).to eq Money.new(6000)
      end
    end

    context 'when a new record is created with a nil value for hourly_charge' do
      before { create(:client) }

      let(:read_back_client) { Client.find_by(name: 'Test One') }

      it 'creates a child record fee with a default value' do
        expect(read_back_client.current_rate).to eq Money.new(6000)
      end
    end
  end

  describe '#current_rate_since' do
    context 'when a new record is built with a nil value for hourly_charge' do
      subject(:test_client) { build(:client) }

      it 'autofills the since date.' do
        expect(test_client.current_rate_since).to eq Time.zone.today
      end
    end
  end

  describe '#new_rate=' do
    context 'when a new client record is built with new_rate set' do
      subject(:test_client) { Client.create!(attributes_for(:client)) }

      it 'creates a corresponding Fee child' do
        expect(test_client.current_rate).to eq Money.new(6000)
      end
    end

    context 'when a new client record is created with current_rate set' do
      subject(:read_back_client) { Client.find_by(name: 'Test One') }

      before { Client.create!(attributes_for(:client, new_rate: Money.new(7000), new_rate_from: Time.zone.today)) }

      it 'creates a corresponding Fee child' do
        expect(read_back_client.current_rate).to eq Money.new(7000)
      end
    end

    context 'when the same new_rate is set a 2nd time' do
      subject(:test_client) do
        Client.create!(attributes_for(:client, new_rate: Money.new(7000), new_rate_from: Time.zone.today))
      end

      it 'does not do an update to the current Fee record' do
        test_client.new_rate = Money.new(7000)
        expect(test_client.current_fee).not_to be_hourly_charge_rate_pence_changed
      end
    end
  end

  describe 'ensure no overlaps on Fee' do
    context 'when non-overlapping Fees exist' do
      subject(:test_client) { build(:client, :with_fees) }

      it 'passes validation' do
        expect(test_client).to be_valid
      end
    end

    context 'when overlapping Fees exist' do
      subject(:test_client) { build(:client, :with_fees, gap: -5.days) }

      it 'fails validation' do
        expect(test_client).not_to be_valid
        expect(test_client.errors[:fees].first).to eq 'fee to 2023-06-01 overlaps with its successor'
      end
    end
  end

  describe '#uninvoiced_sessions' do
    context 'when client has uninvoiced sessions' do
      let(:client) { create(:client, :with_client_sessions) }

      it 'returns all client sessions that have not been invoiced' do
        expect(client.uninvoiced_sessions.count).to eq(client.client_sessions.count)
      end
    end

    context 'when client has some invoiced sessions' do
      let(:client) { create(:client) }
      let!(:invoice) { create(:invoice, client: client) }
      let!(:invoiced_session) { create(:client_session, client: client, invoice: invoice) }
      let!(:uninvoiced_sessions) { create_list(:client_session, 2, client: client) }

      it 'returns only uninvoiced sessions' do
        expect(client.uninvoiced_sessions.count).to eq(2)
        expect(client.uninvoiced_sessions).to match_array(uninvoiced_sessions)
      end
    end

    context 'when client has no sessions' do
      let(:client) { create(:client) }

      it 'returns an empty collection' do
        expect(client.uninvoiced_sessions).to be_empty
      end
    end
  end

  describe '#uninvoiced_amount' do
    context 'when client has uninvoiced sessions' do
      let(:client) { create(:client, :with_client_sessions) }

      it 'returns the sum of all uninvoiced session fees' do
        expect(client.uninvoiced_amount).to eq(Money.new(6000 * client.client_sessions.count))
      end
    end

    context 'when client has some invoiced sessions' do
      let(:client) { create(:client) }

      it 'returns the sum of only uninvoiced session fees' do
        create(:invoice, client: client)
        create_list(:client_session, 2, client: client)

        expect(client.uninvoiced_amount).to eq(Money.new(6000 * 2))
      end
    end
  end

  describe '#applicable_messages' do
    let(:client) { create(:client) }
    let(:other_client) { create(:client, name: "Other Client") }
    let(:today) { Date.new(2025, 6, 19) }

    before do
      # Mock the current date to ensure consistent test results
      allow(Date).to receive(:today).and_return(today)
    end

    context 'with client-specific messages' do
      it 'includes messages specifically assigned to the client' do
        client_message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        client_message.apply_to_client(client)

        expect(client.applicable_messages).to include(client_message)
      end

      it 'does not include messages assigned to other clients' do
        other_client_message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        other_client_message.apply_to_client(other_client)

        expect(client.applicable_messages).not_to include(other_client_message)
      end
    end

    context 'with global messages' do
      it 'includes global messages that apply to all clients' do
        global_message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        global_message.all_clients = true

        expect(client.applicable_messages).to include(global_message)
        expect(other_client.applicable_messages).to include(global_message)
      end
    end

    context 'with date filtering' do
      it 'only includes current messages' do
        # Current client-specific message
        current_message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        current_message.apply_to_client(client)

        # Expired client-specific message
        expired_message = create(:message, from_date: today - 10.days, until_date: today - 1.day)
        expired_message.apply_to_client(client)

        # Future client-specific message
        future_message = create(:message, from_date: today + 1.day, until_date: today + 10.days)
        future_message.apply_to_client(client)

        expect(client.applicable_messages).to include(current_message)
        expect(client.applicable_messages).not_to include(expired_message)
        expect(client.applicable_messages).not_to include(future_message)
      end

      it 'includes messages with no date restrictions' do
        unrestricted_message = create(:message, from_date: nil, until_date: nil)
        unrestricted_message.apply_to_client(client)

        expect(client.applicable_messages).to include(unrestricted_message)
      end
    end

    context 'with mixed message types' do
      it 'returns all applicable messages without duplicates' do
        # Client-specific message
        client_message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        client_message.apply_to_client(client)

        # Global message
        global_message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        global_message.all_clients = true

        # Other client's message
        other_client_message = create(:message, from_date: today - 5.days, until_date: today + 5.days)
        other_client_message.apply_to_client(other_client)

        # Non-current message for this client
        expired_message = create(:message, from_date: today - 10.days, until_date: today - 1.day)
        expired_message.apply_to_client(client)

        applicable_messages = client.applicable_messages

        expect(applicable_messages).to include(client_message)
        expect(applicable_messages).to include(global_message)
        expect(applicable_messages).not_to include(other_client_message)
        expect(applicable_messages).not_to include(expired_message)
        expect(applicable_messages.count).to eq(2)
      end
    end
  end
end
