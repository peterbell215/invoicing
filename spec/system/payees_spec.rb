require 'rails_helper'

RSpec.describe "Payees", type: :system do
  describe "New payee" do
    subject(:new_payee) { FactoryBot.build(:payee) }

    it "allows adding a new payee with valid information" do
      visit new_payee_path

      # Fill in payee information
      fill_in "Name", with: new_payee.name
      fill_in "Organisation", with: new_payee.organisation
      fill_in "Email", with: new_payee.email
      fill_in "Address Line 1", with: new_payee.address1
      fill_in "Town", with: new_payee.town
      fill_in "Postcode", with: new_payee.postcode

      # Submit the form
      click_button "Create Payee"

      # Read the created record and check that it matches what was entered.
      expect(page).to have_content("Payee was successfully created")

      created_payee = Payee.find_by(email: new_payee.email)
      expect(created_payee).to have_attributes(
        name: new_payee.name, 
        organisation: new_payee.organisation,
        email: new_payee.email, 
        address1: new_payee.address1,
        town: new_payee.town, 
        postcode: new_payee.postcode
      )
    end

    it "shows validation errors when submitting invalid information", js: true do
      visit new_payee_path

      # Submit without filling any fields
      click_button "Create Payee"

      # Expect to see validation errors
      expect(page).to have_content("prohibited this record from being saved")
      expect(page).to have_content("Name can't be blank")
      expect(page).to have_content("Email can't be blank")
      expect(page).to have_content("Address Line 1 can't be blank")
      expect(page).to have_content("Town can't be blank")

      # Fill in just one field and submit again
      fill_in "Name", with: "The Bursar"
      click_button "Create Payee"

      # Should still show errors for other fields
      expect(page).to have_content("prohibited this record from being saved")
      expect(page).not_to have_content("Name can't be blank")
      expect(page).to have_content("Email can't be blank")
    end

    it "validates postcode format" do
      visit new_payee_path

      # Fill in all required fields but with an invalid postcode
      fill_in "Name", with: "The Bursar"
      fill_in "Organisation", with: "The College"
      fill_in "Email", with: "bursar@college.edu"
      fill_in "Address Line 1", with: "Financial Office"
      fill_in "Town", with: "Cambridge"
      fill_in "Postcode", with: "invalid"

      # Submit the form
      click_button "Create Payee"

      # Expect to see postcode validation error
      expect(page).to have_content("Postcode is badly formed postcode")

      # Fix the postcode and try again
      fill_in "Postcode", with: "CB2 1TN"
      click_button "Create Payee"

      # Should be successful now
      expect(page).to have_content("Payee was successfully created")
    end
  end

  describe "Active flag functionality" do
    let!(:active_payee) { FactoryBot.create(:payee, name: "Active Payee", active: true) }
    let!(:inactive_payee) { FactoryBot.create(:payee, name: "Inactive Payee", active: false) }

    it "sets new payees as active by default" do
      visit new_payee_path

      # Fill in minimum required information
      fill_in "Name", with: "New Test Payee"
      fill_in "Email", with: "test@example.com"
      fill_in "Address Line 1", with: "123 Test St"
      fill_in "Town", with: "Testville"
      fill_in "Postcode", with: "SW1A 1AA"

      # Submit the form
      click_button "Create Payee"

      # Verify payee was created and is active by default
      expect(page).to have_content("Payee was successfully created")
      created_payee = Payee.find_by(email: "test@example.com")
      expect(created_payee.active).to be true
    end

    it "does not show active toggle when creating a payee" do
      visit new_payee_path
      expect(page).not_to have_content("Active Payee")
    end

    it "shows active toggle when editing an active payee" do
      visit edit_payee_path(active_payee)
      expect(page).to have_content("Active Payee")
      expect(page).to have_field('payee_active', visible: false, checked: true)
    end

    it "shows in-active toggle when editing an inactive payee" do
      visit edit_payee_path(inactive_payee)
      expect(page).to have_content("Active Payee")
      expect(page).to have_field('payee_active', visible: false, checked: false)
    end

    it "allows changing payee to inactive status" do
      # Make active payee inactive
      visit edit_payee_path(active_payee)

      find("label[for='payee_active']").click
      click_button "Update Payee"

      expect(page).to have_content("Payee was successfully updated")
      expect(active_payee.reload.active).to be false
    end

    it "allows changing payee to active status" do
      # Make inactive payee active
      visit edit_payee_path(inactive_payee)

      find("label[for='payee_active']").click
      click_button "Update Payee"

      expect(page).to have_content("Payee was successfully updated")
      expect(inactive_payee.reload.active).to be true
    end

    it "displays active status on payee show page" do
      visit payee_path(active_payee)
      within('.status-badge.active') do
        expect(page).to have_content("Yes")
      end

      visit payee_path(inactive_payee)
      within('.status-badge.inactive') do
        expect(page).to have_content("No")
      end
    end

    it "displays active status in payee index" do
      visit payees_path

      within("#payee_#{active_payee.id}") do
        expect(page).to have_selector('.status-badge.active', text: 'Active')
      end

      within("#payee_#{inactive_payee.id}") do
        expect(page).to have_selector('.status-badge.inactive', text: 'Inactive')
      end
    end

    it "filters payees based on active status" do
      visit payees_path

      # Initially should show all payees
      expect(page).to have_content("Active Payee")
      expect(page).to have_content("Inactive Payee")

      # Filter to show only active payees
      find("label[for='active_only']").click

      # Should now only show active payees
      expect(page).to have_content("Active Payee")
      expect(page).not_to have_content("Inactive Payee")

      # Uncheck to show all payees again
      find("label[for='active_only']").click

      # Should show all payees again
      expect(page).to have_content("Active Payee")
      expect(page).to have_content("Inactive Payee")
    end
  end

  describe "Deletion restrictions" do
    let!(:payee_with_clients) { FactoryBot.create(:payee, name: "Payee with Clients") }
    let!(:payee_without_clients) { FactoryBot.create(:payee, name: "Payee without Clients") }
    let!(:client) { FactoryBot.create(:client, paid_by: payee_with_clients) }

    it "prevents deletion of payee with associated clients", js: true do
      visit payees_path

      within("#payee_#{payee_with_clients.id} > td.action-buttons") do
        expect(page).not_to have_button("Delete")
      end
    end

    it "allows deletion of payee without associated clients", js: true do
      visit payees_path

      within("#payee_#{payee_without_clients.id}") do
        click_button "Delete"
      end

      # Should show confirmation dialog
      within("dialog") do
        expect(page).to have_content("Are you sure you want to delete: #{payee_without_clients.name}")
        click_button "Delete"
      end

      # Should show success message
      expect(page).to have_content("Payee was successfully destroyed")
      
      # Payee should be deleted
      expect(Payee.exists?(payee_without_clients.id)).to be false
    end

    it "does not show delete button for payee with clients" do
      visit payee_path(payee_with_clients)
      
      expect(page).not_to have_button("Delete")
    end

    it "shows delete button for payee without clients" do
      visit payee_path(payee_without_clients)
      
      expect(page).to have_button("Delete")
    end
  end

  describe "Client associations display" do
    let!(:payee) { FactoryBot.create(:payee, name: "Test Payee") }
    let!(:client1) { FactoryBot.create(:client, name: "Client One", paid_by: payee) }
    let!(:client2) { FactoryBot.create(:client, name: "Client Two", paid_by: payee) }

    it "displays associated clients on payee show page" do
      visit payee_path(payee)

      expect(page).to have_content("Clients (2)")
      expect(page).to have_content("Client One")
      expect(page).to have_content("Client Two")
    end

    it "displays client count in payee index" do
      visit payees_path

      within("#payee_#{payee.id}") do
        expect(page).to have_content("2 clients")
      end
    end

    it "shows zero clients for payee without clients" do
      payee_no_clients = FactoryBot.create(:payee, name: "No Clients Payee")
      
      visit payees_path

      within("#payee_#{payee_no_clients.id}") do
        expect(page).to have_content("0 clients")
      end
    end
  end
end
