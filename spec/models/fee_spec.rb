require 'rails_helper'

RSpec.describe Fee, type: :model do
  let(:client) { FactoryBot.create(:client) }

  describe "monetization" do
    it "monetizes unit_charge_rate_pence" do
      fee = Fee.new(client: client, unit_charge_rate_pence: 6000)
      expect(fee.unit_charge_rate).to be_a(Money)
      expect(fee.unit_charge_rate.cents).to eq(6000)
    end
  end

  describe "validations" do
    let(:fee) { FactoryBot.build(:fee, client: client) }

    it "is valid with valid attributes" do
      expect(fee).to be_valid
    end

    it "requires a client" do
      fee.client = nil
      expect(fee).not_to be_valid
    end
  end

  describe ".overlap?" do
    let!(:fee1) { FactoryBot.create(:fee, client: client, from: Date.parse('2023-01-01'), to: Date.parse('2023-06-30')) }
    let!(:fee2) { FactoryBot.create(:fee, client: client, from: Date.parse('2023-07-01'), to: Date.parse('2023-12-31')) }

    context "when fees do not overlap" do
      it "returns false for non-overlapping fees" do
        fees = [fee1, fee2]
        expect(Fee.overlap?(fees)).to be_falsey
      end

      it "returns false for single fee" do
        fees = [fee1]
        expect(Fee.overlap?(fees)).to be_falsey
      end

      it "returns false for empty array" do
        fees = []
        expect(Fee.overlap?(fees)).to be_falsey
      end
    end

    context "when fees overlap" do
      let!(:overlapping_fee) { FactoryBot.create(:fee, client: client, from: Date.parse('2023-06-15'), to: Date.parse('2023-08-15')) }

      it "returns the first overlapping fee" do
        fees = [fee1, overlapping_fee, fee2]
        expect(Fee.overlap?(fees)).to eq(fee1)
      end

      it "detects overlap when second fee starts before first fee ends" do
        fee_a = FactoryBot.create(:fee, client: client, from: Date.parse('2023-01-01'), to: Date.parse('2023-03-31'))
        fee_b = FactoryBot.create(:fee, client: client, from: Date.parse('2023-03-15'), to: Date.parse('2023-06-30'))
        fees = [fee_a, fee_b]

        expect(Fee.overlap?(fees)).to eq(fee_a)
      end

      it "detects same start dates as overlap" do
        fee_a = FactoryBot.create(:fee, client: client, from: Date.parse('2023-01-01'), to: Date.parse('2023-03-31'))
        fee_b = FactoryBot.create(:fee, client: client, from: Date.parse('2023-01-01'), to: Date.parse('2023-06-30'))
        fees = [fee_a, fee_b]

        expect(Fee.overlap?(fees)).to eq(fee_a)
      end
    end

    context "edge cases" do
      it "does not consider adjacent dates as overlapping" do
        fee_a = FactoryBot.create(:fee, client: client, from: Date.parse('2023-01-01'), to: Date.parse('2023-03-31'))
        fee_b = FactoryBot.create(:fee, client: client, from: Date.parse('2023-04-01'), to: Date.parse('2023-06-30'))
        fees = [fee_a, fee_b]

        expect(Fee.overlap?(fees)).to be_falsey
      end
    end
  end

  describe "date range scenarios" do
    context "with multiple fees for same client" do
      it "can have multiple non-overlapping fees" do
        fee1 = FactoryBot.create(:fee, client: client, from: Date.parse('2023-01-01'), to: Date.parse('2023-06-30'))
        fee2 = FactoryBot.create(:fee, client: client, from: Date.parse('2023-07-01'), to: Date.parse('2023-12-31'))
        client.reload

        expect(client.fees).to include(fee1, fee2)
        expect(Fee.overlap?([fee1, fee2])).to be_falsey
      end

      it "handles open-ended date ranges" do
        fee = FactoryBot.create(:fee, client: client, from: Date.parse('2023-01-01'), to: nil)
        expect(fee).to be_valid
      end
    end
  end
end
