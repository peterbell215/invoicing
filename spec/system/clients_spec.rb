require 'rails_helper'

RSpec.describe "Clients", type: :system do
  describe "New client" do
    subject(:new_client) { FactoryBot.build(:client) }

    it "allows adding a new client with valid information" do
      visit new_client_path
      
      # Fill in client information
      fill_in "Name", with: new_client.name
      fill_in "Email", with: new_client.email
      fill_in "Address Line 1", with: new_client.address1
      fill_in "Town", with: new_client.town
      fill_in "Postcode", with: new_client.postcode
      
      # Fill in billing information
      fill_in "Hourly Rate", with: "85.00"
      
      # Submit the form
      click_button "Create Client"

      # Read the created record and check that it matches what was entered.
      expect(page).to have_content("Client was successfully created")

      created_client = Client.find_by(email: new_client.email)
      expect(created_client).to have_attributes(name: new_client.name, email: new_client.email, address1: new_client.address1,
        town: new_client.town, postcode: new_client.postcode)
      expect(created_client.current_rate.to_s).to eq("85.00")
    end

    it "shows validation errors when submitting invalid information" do
      visit new_client_path
      
      # Submit without filling any fields
      click_button "Create Client"
      
      # Expect to see validation errors
      expect(page).to have_content("prohibited this client from being saved")
      expect(page).to have_content("Name can't be blank")
      expect(page).to have_content("Email can't be blank")
      expect(page).to have_content("Address1 can't be blank")
      expect(page).to have_content("Town can't be blank")
      expect(page).to have_content("Postcode is badly formed postcode")
      
      # Fill in just one field and submit again
      fill_in "Name", with: "John Smith Consulting"
      click_button "Create Client"
      
      # Should still show errors for other fields
      expect(page).to have_content("prohibited this client from being saved")
      expect(page).not_to have_content("Name can't be blank")
      expect(page).to have_content("Email can't be blank")
    end
    
    it "validates postcode format" do
      visit new_client_path
      
      # Fill in all required fields but with an invalid postcode
      fill_in "Name", with: "John Smith Consulting"
      fill_in "Email", with: "john@smithconsulting.com"
      fill_in "Address Line 1", with: "123 Business Lane"
      fill_in "Town", with: "London"
      fill_in "Postcode", with: "invalid"
      fill_in "Hourly Rate", with: "85.00"
      
      # Submit the form
      click_button "Create Client"
      
      # Expect to see postcode validation error
      expect(page).to have_content("Postcode is badly formed postcode")
      
      # Fix the postcode and try again
      fill_in "Postcode", with: "SW1A 1AA"
      click_button "Create Client"
      
      # Should be successful now
      expect(page).to have_content("Client was successfully created")
    end
  end
end