require 'rails_helper'

RSpec.describe "Messages", type: :system do
  include ActionText::SystemTestHelper

  let!(:clients) { create_list(:client, 3) }

  describe "Creating a message" do
    it "allows creating a message for all clients" do
      visit new_message_path

      fill_in_rich_textarea "Message Text", with: "Important announcement for all clients"
      fill_in "From Date (optional)", with: Date.current.strftime("%d/%m/%Y")
      fill_in "Until Date (optional)", with: (Date.current + 30.days).strftime("%d/%m/%Y")

      check "Apply to all clients"

      click_button "Create Message"

      expect(page).to have_content("Message was successfully created")

      # Verify the message was created correctly
      created_message = Message.last
      expect(created_message.text.to_plain_text).to eq("Important announcement for all clients")
      expect(created_message.all_clients).to be true
      expect(created_message.from_date).to eq(Date.current)
      expect(created_message.until_date).to eq(Date.current + 30.days)
    end

    it "allows creating a message for specific clients" do
      visit new_message_path

      fill_in_rich_textarea "Message Text", with: "Message for selected clients only"

      # Don't check "Apply to all clients"
      check clients[0].name
      check clients[2].name

      click_button "Create Message"

      expect(page).to have_content("Message was successfully created")

      # Verify the message was created correctly
      created_message = Message.last
      expect(created_message.text.to_plain_text).to eq("Message for selected clients only")
      expect(created_message.all_clients).to be false
      expect(created_message.clients.count).to eq(2)
      expect(created_message.clients.pluck(:name)).to include(clients[0].name, clients[2].name)
      expect(created_message.clients.pluck(:name)).not_to include(clients[1].name)
    end

    it "allows creating a message without date restrictions" do
      visit new_message_path

      fill_in_rich_textarea "Message Text", with: "Permanent message"
      check "Apply to all clients"

      click_button "Create Message"

      expect(page).to have_content("Message was successfully created")

      created_message = Message.last
      expect(created_message.from_date).to be_nil
      expect(created_message.until_date).to be_nil
    end

    it "shows validation errors when message text is missing" do
      visit new_message_path

      check "Apply to all clients"
      click_button "Create Message"

      expect(page).to have_content("prohibited this message from being saved")
    end
  end

  describe "Viewing messages" do
    let!(:all_clients_message) { create(:message, :for_all_clients, text: "Message for everyone") }
    let!(:specific_clients_message) do
      message = create(:message, text: "Message for some clients")
      message.apply_to_client(clients[0])
      message.apply_to_client(clients[1])
      message
    end

    it "displays messages in the index with correct recipient information" do
      visit messages_path

      expect(page).to have_content("Messages")

      # Check all clients message
      within("table") do
        expect(page).to have_content("Message for everyone")
        expect(page).to have_content("All clients")
      end

      # Check specific clients message
      within("table") do
        expect(page).to have_content("Message for some clients")
        expect(page).to have_content("2 clients")
      end
    end
  end

  describe "Editing a message" do
    let!(:message) { create(:message, text: "Original message text", from_date: Date.current) }

    before do
      message.apply_to_client(clients[0])
      message.apply_to_client(clients[1])
    end

    it "allows editing message content and dates" do
      visit edit_message_path(message)

      fill_in_rich_textarea "Message Text", with: "Updated message content"
      fill_in "From Date (optional)", with: (Date.current + 1.day).strftime("%d/%m/%Y")
      fill_in "Until Date (optional)", with: (Date.current + 60.days).strftime("%d/%m/%Y")

      click_button "Update Message"

      expect(page).to have_content("Message was successfully updated")

      message.reload
      expect(message.text.to_plain_text).to eq("Updated message content")
      expect(message.from_date).to eq(Date.current + 1.day)
      expect(message.until_date).to eq(Date.current + 60.days)
    end

    it "allows changing from specific clients to all clients" do
      visit edit_message_path(message)

      # Initially should show the specific clients selected
      expect(page).to have_checked_field("Test One")
      expect(page).to have_checked_field("Test Two")
      expect(page).not_to have_checked_field("Test Three")
      expect(page).not_to have_checked_field("Apply to all clients")

      # Change to all clients
      check "Apply to all clients"

      click_button "Update Message"

      expect(page).to have_content("Message was successfully updated")

      message.reload
      expect(message.all_clients).to be true
      expect(message.clients.count).to eq(0) # No specific client associations when all_clients is true
    end

    it "allows changing from all clients to specific clients" do
      message.update!(all_clients: true)
      message.messages_for_clients.create!(client_id: nil) # Create the all clients association

      visit edit_message_path(message)

      # Should show "Apply to all clients" checked
      expect(page).to have_checked_field("Apply to all clients")

      # Uncheck "Apply to all clients" and select specific clients
      uncheck "Apply to all clients"
      check "Test One"
      check "Test Three"

      click_button "Update Message"

      expect(page).to have_content("Message was successfully updated")

      message.reload
      expect(message.all_clients).to be false
      expect(message.clients.count).to eq(2)
      expect(message.clients.pluck(:name)).to include("Test One", "Test Three")
    end

    it "allows changing which specific clients receive the message" do
      visit edit_message_path(message)

      # Initially Alpha and Beta are selected
      expect(page).to have_checked_field("Test One")
      expect(page).to have_checked_field("Test Two")
      expect(page).not_to have_checked_field("Test Three")

      # Change selection to Beta and Gamma
      uncheck "Test One"
      check "Test Three"

      click_button "Update Message"

      expect(page).to have_content("Message was successfully updated")

      message.reload
      expect(message.clients.count).to eq(2)
      expect(message.clients.pluck(:name)).to include("Test Two", "Test Three")
      expect(message.clients.pluck(:name)).not_to include("Test One")
    end

    it "shows validation errors when trying to update with invalid data" do
      visit edit_message_path(message)

      # Clear the message text
      fill_in_rich_textarea "Message Text", with: ""

      click_button "Update Message"

      expect(page).to have_content("prohibited this message from being saved")
      expect(current_path).to eq(edit_message_path(message)) # Should render edit template
    end
  end

  describe "Deleting a message" do
    let!(:message) { create(:message, text: "Message to be deleted") }

    before do
      message.apply_to_client(clients[0])
    end

    it "allows deleting a message with confirmation" do
      visit messages_path

      expect(page).to have_content("Message to be deleted")

      # Click delete button to open the confirmation dialog
      click_button "Delete"

      # Wait for dialog to appear and verify its content
      expect(page).to have_selector('#delete-confirmation-dialog[open]')
      expect(page).to have_content("Are you sure you want to delete the message:")
      expect(page).to have_content("Message to be deleted")

      # Click the Delete button in the dialog to confirm
      within('#delete-confirmation-dialog') do
        click_button "Delete"
      end

      expect(page).to have_content("Message was successfully deleted")
      expect(page).not_to have_content("Message to be deleted")

      # Verify message was actually deleted
      expect(Message.exists?(message.id)).to be false
    end

    it "does not delete message if confirmation is cancelled" do
      visit messages_path

      expect(page).to have_content("Message to be deleted")

      # Click delete button to open the confirmation dialog
      click_button "Delete"

      # Wait for dialog to appear
      expect(page).to have_selector('#delete-confirmation-dialog[open]')

      # Click Cancel button in the dialog
      within('#delete-confirmation-dialog') do
        click_button "Cancel"
      end

      # Dialog should close and message should still exist
      expect(page).not_to have_selector('#delete-confirmation-dialog[open]')
      expect(page).to have_content("Message to be deleted")
      expect(Message.exists?(message.id)).to be true
    end

    it "can close the dialog by clicking outside" do
      visit messages_path

      expect(page).to have_content("Message to be deleted")

      # Click delete button to open the confirmation dialog
      click_button "Delete"

      # Wait for dialog to appear
      expect(page).to have_selector('#delete-confirmation-dialog[open]')

      # Click outside the dialog (on the backdrop)
      page.execute_script("document.querySelector('#delete-confirmation-dialog').click()")

      # Dialog should close and message should still exist
      expect(page).not_to have_selector('#delete-confirmation-dialog[open]')
      expect(page).to have_content("Message to be deleted")
      expect(Message.exists?(message.id)).to be true
    end
  end

  describe "Message recipient display and management" do
    let!(:all_clients_message) do
      message = create(:message, text: "All clients message")
      message.all_clients = true
      message.save!
      message
    end

    let!(:no_clients_message) { create(:message, text: "No clients message") }

    let!(:single_client_message) do
      message = create(:message, text: "Single client message")
      message.apply_to_client(clients[0])
      message
    end

    let!(:multiple_clients_message) do
      message = create(:message, text: "Multiple clients message")
      clients.each { |client| message.apply_to_client(client) }
      message
    end

    it "correctly displays recipient counts in the index" do
      visit messages_path

      within("table") do
        # All clients message
        expect(page).to have_content("All clients message")
        expect(page).to have_content("All clients")

        # Single client message
        expect(page).to have_content("Single client message")
        expect(page).to have_content("1 client")

        # Multiple clients message
        expect(page).to have_content("Multiple clients message")
        expect(page).to have_content("3 clients")

        # No clients message
        expect(page).to have_content("No clients message")
        expect(page).to have_content("0 clients")
      end
    end
  end

  describe "JavaScript client selection behavior" do
    it "disables client checkboxes when 'Apply to all clients' is checked", js: true do
      visit new_message_path

      fill_in_rich_textarea "Message Text", with: "Test message"

      # Initially, client checkboxes should be enabled
      expect(page).to have_field("Test One", disabled: false)
      expect(page).to have_field("Test Two", disabled: false)
      expect(page).to have_field("Test Three", disabled: false)

      # Check "Apply to all clients"
      check "Apply to all clients"

      # Client checkboxes should now be disabled
      expect(page).to have_field("Test One", disabled: true)
      expect(page).to have_field("Test Two", disabled: true)
      expect(page).to have_field("Test Three", disabled: true)

      # Uncheck "Apply to all clients"
      uncheck "Apply to all clients"

      # Client checkboxes should be enabled again
      expect(page).to have_field("Test One", disabled: false)
      expect(page).to have_field("Test Two", disabled: false)
      expect(page).to have_field("Test Three", disabled: false)
    end
  end
end
