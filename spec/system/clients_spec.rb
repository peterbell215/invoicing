require 'rails_helper'

RSpec.describe "Clients", type: :system do
  describe "New client" do
    it "allows adding a new client with valid information" do
      visit new_client_path
      
      # Fill in client information
      fill_in "Name", with: "John Smith Consulting"
      fill_in "Email", with: "john@smithconsulting.com"
      fill_in "Address Line 1", with: "123 Business Lane"
      fill_in "Address Line 2", with: "Suite 456"
      fill_in "Town", with: "London"
      fill_in "Postcode", with: "SW1A 1AA"
      
      # Fill in billing information
      fill_in "Hourly Rate", with: "85.00"
      
      # Submit the form
      click_button "Create Client"
      
      # Expect to be redirected to the client's show page
      expect(page).to have_content("Client was successfully created")
      expect(page).to have_content("John Smith Consulting")
      expect(page).to have_content("john@smithconsulting.com")
      expect(page).to have_content("123 Business Lane")
      expect(page).to have_content("London")
      expect(page).to have_content("SW1A 1AA")
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