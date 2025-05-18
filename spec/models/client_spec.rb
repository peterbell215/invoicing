require 'rails_helper'

describe Client do
  describe 'FactoryBot' do
    context 'when FactoryBot builds a client' do
      subject(:test_client) { build(:client) }

      specify { expect(test_client.name).to eq('Test Client') }
    end

    context 'when Factorybot builds a client with fees' do
      subject(:test_client) { build(:client, :with_fees) }

      specify { expect(test_client.fees.length).to eq 3 }
      specify { expect(test_client.fees[0].from).to eq Date.new(2022, 12, 1) }
      specify { expect(test_client.fees[0].to + 1.day).to eq test_client.fees[1].from }
    end

    context 'when FactoryBot builds a client with client sessions' do
      subject(:test_client) { build(:client, :with_client_sessions) }

      specify { expect(test_client.client_sessions.length).to eq 4 }
      specify { expect(test_client.client_sessions[0].start).to eq DateTime.new(2024, 2, 1, 9, 0) }
      specify { expect(test_client.client_sessions[0].duration).to eq 60 }
      specify { expect(test_client.client_sessions[0].start + 1.week).to eq test_client.client_sessions[1].start }
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

    it 'is not possible to leave #new_rate_from blank if #new_rate set' do
      expect(build(:client, new_rate: nil, new_rate_from: Time.zone.today)).not_to be_valid
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

      let(:read_back_client) { Client.find_by(name: 'Test Client') }

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
      subject(:read_back_client) { Client.find_by(name: 'Test Client') }

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
end

