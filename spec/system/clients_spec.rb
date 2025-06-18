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
      expect(page).to have_content("Address Line 1 can't be blank")
      expect(page).to have_content("Town can't be blank")

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

  describe "Active flag functionality" do
    let!(:active_client) { FactoryBot.create(:client, name: "Active Client", active: true) }
    let!(:inactive_client) { FactoryBot.create(:client, name: "Inactive Client", active: false) }

    it "sets new clients as active by default" do
      visit new_client_path

      # Fill in minimum required information
      fill_in "Name", with: "New Test Client"
      fill_in "Email", with: "test@example.com"
      fill_in "Address Line 1", with: "123 Test St"
      fill_in "Town", with: "Testville"
      fill_in "Postcode", with: "SW1A 1AA"

      # Submit the form
      click_button "Create Client"

      # Verify client was created and is active by default
      expect(page).to have_content("Client was successfully created")
      created_client = Client.find_by(email: "test@example.com")
      expect(created_client.active).to be true
    end

    it "does not show active toggle when creating a client" do
      visit new_client_path
      expect(page).not_to have_content("Active Client")
    end

    it "shows active toggle when editing an active client" do
      visit edit_client_path(active_client)
      expect(page).to have_content("Active Client")
      expect(page).to have_field('client_active', visible: false, checked: true)
    end

    it "shows in-active toggle when editing an inactive client" do
      visit edit_client_path(inactive_client)
      expect(page).to have_content("Active Client")
      expect(page).to have_field('client_active', visible: false, checked: false)
    end

    it "allows changing client to inactive status" do
      # Make active client inactive
      visit edit_client_path(active_client)

      find("label[for='client_active']").click
      click_button "Update Client"

      expect(page).to have_content("Client was successfully updated")
      expect(active_client.reload.active).to be false
    end

    it "allows changing client to active status" do
      # Make inactive client active
      visit edit_client_path(inactive_client)

      find("label[for='client_active']").click
      click_button "Update Client"

      expect(page).to have_content("Client was successfully updated")
      expect(inactive_client.reload.active).to be true
    end

    it "displays active status on client show page" do
      visit client_path(active_client)
      within('.status-badge.active') do
        expect(page).to have_content("Yes")
      end

      visit client_path(inactive_client)
      within('.status-badge.inactive') do
        expect(page).to have_content("No")
      end
    end

    it "displays active status in client index" do
      visit clients_path

      within("#client_#{active_client.id}") do
        expect(page).to have_selector('.status-badge.active', text: 'Active')
      end

      within("#client_#{inactive_client.id}") do
        expect(page).to have_selector('.status-badge.inactive', text: 'Inactive')
      end
    end

    it "filters clients based on active status" do
      visit clients_path

      # Initially should show all clients
      expect(page).to have_content("Active Client")
      expect(page).to have_content("Inactive Client")

      # Filter to show only active clients
      find("label[for='active_only']").click

      # Should now only show active clients
      expect(page).to have_content("Active Client")
      expect(page).not_to have_content("Inactive Client")

      # Uncheck to show all clients again
      find("label[for='active_only']").click

      # Should show all clients again
      expect(page).to have_content("Active Client")
      expect(page).to have_content("Inactive Client")
    end
  end

  describe "Payee Reference functionality" do
    let!(:payee) { FactoryBot.create(:payee) }

    it "hides payee reference field when self-paying is selected", js:true do
      visit new_client_path

      puts Capybara.default_driver
      puts Capybara.current_driver
      puts Capybara.javascript_driver

      # Check that the payee reference field is initially hidden
      expect(page).to have_select('client_paid_by_id', selected: 'Self Paying')
      expect(page).to have_css('div[data-payee-reference-target="referenceField", display:none]', visible: false)
    end

    it "shows payee reference field when a payee is selected" do
      visit new_client_path

      # Initially hidden
      expect(page).to have_css('div[data-payee-reference-target="referenceField"].hidden')

      # Select a payee
      select payee.name, from: 'client_paid_by_id'

      # Field should now be visible
      expect(page).not_to have_css('div[data-payee-reference-target="referenceField"].hidden')
    end

    it "saves payee reference when creating a client with a payee" do
      visit new_client_path

      # Fill in required client fields
      fill_in "Name", with: "Client with Payee"
      fill_in "Email", with: "clientwithpayee@example.com"
      fill_in "Address Line 1", with: "123 Test St"
      fill_in "Town", with: "Testville"
      fill_in "Postcode", with: "SW1A 1AA"

      # Select a payee and add a reference
      select payee.name, from: 'client_paid_by_id'
      fill_in "Payee Reference", with: "PO-12345"

      # Submit the form
      click_button "Create Client"

      # Verify client was created with correct payee reference
      expect(page).to have_content("Client was successfully created")
      created_client = Client.find_by(email: "clientwithpayee@example.com")
      expect(created_client.payee_reference).to eq("PO-12345")
    end

    it "clears payee reference when switching from payee to self-paying" do
      # First create a client with a payee reference
      client_with_reference = FactoryBot.create(
        :client,
        name: "Reference Client",
        paid_by: payee,
        payee_reference: "EXISTING-REF"
      )

      # Edit the client
      visit edit_client_path(client_with_reference)

      # Verify the payee and reference are correctly loaded
      expect(page).to have_select('client_paid_by_id', selected: payee.name)
      expect(page).to have_field('client_payee_reference', with: "EXISTING-REF")

      # Change to self-paying
      select "Self Paying", from: 'client_paid_by_id'

      # The reference field should be hidden but still contain the value
      expect(page).to have_css('div[data-payee-reference-target="referenceField"].hidden')

      # Submit the form
      click_button "Update Client"

      # Verify client was updated and reference was cleared
      expect(page).to have_content("Client was successfully updated")
      client_with_reference.reload
      expect(client_with_reference.paid_by).to be_nil
      expect(client_with_reference.payee_reference).to be_nil
    end
  end
end
