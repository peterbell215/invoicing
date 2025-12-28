require 'rails_helper'

RSpec.describe NoClientPayeeSetError do
  describe 'initialization' do
    it 'can be raised and caught' do
      expect { raise NoClientPayeeSetError }.to raise_error(NoClientPayeeSetError)
    end

    it 'has a default error message' do
      error = NoClientPayeeSetError.new
      expect(error.message).to eq("Cannot set self_paid to true: client does not have a payee configured")
    end

    it 'accepts a custom error message' do
      custom_message = "Custom error message"
      error = NoClientPayeeSetError.new(custom_message)
      expect(error.message).to eq(custom_message)
    end

    it 'is a subclass of StandardError' do
      expect(NoClientPayeeSetError.new).to be_a(StandardError)
    end
  end
end

