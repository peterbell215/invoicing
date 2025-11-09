require 'rails_helper'

RSpec.describe "Client Sessions", type: :system do
  let!(:client) { FactoryBot.create(:client) }
  let!(:payee) { FactoryBot.create(:payee) }

  describe "Index page" do
    let!(:client_session1) { FactoryBot.create(:client_session, client: client, session_date: 1.week.ago, units: 1.0, description: "First session") }
    let!(:client_session2) { FactoryBot.create(:client_session, client: client, session_date: 2.days.ago, units: 1.5, description: "Second session") }

    it "displays all client sessions ordered by date" do
      visit client_sessions_path

      expect(page).to have_content("Client Sessions")
      expect(page).to have_content(client.name)
      expect(page).to have_content("First session")
      expect(page).to have_content("Second session")
      expect(page).to have_content("1.0")
      expect(page).to have_content("1.5")

      # Check that sessions are ordered by session_date ascending
      session_rows = page.all("tbody tr")
      expect(session_rows.first).to have_content("First session")
      expect(session_rows.last).to have_content("Second session")
    end

    it "shows invoice status for each session" do
      invoice = FactoryBot.create(:invoice, client: client, status: 'created')
      client_session1.update!(invoice: invoice)

      visit client_sessions_path

      within("##{dom_id(client_session1)}") do
        expect(page).to have_content("Created")
      end

      within("##{dom_id(client_session2)}") do
        expect(page).to have_content("Unbilled")
      end
    end

    it "provides action buttons for each session" do
      visit client_sessions_path

      within("##{dom_id(client_session1)}") do
        expect(page).to have_link("View")
        expect(page).to have_link("Edit")
        expect(page).to have_button("Delete")
      end
    end

    it "hides edit and delete buttons for sessions with sent or paid invoice status" do
      sent_invoice = FactoryBot.create(:invoice, client: client, status: 'sent')
      paid_invoice = FactoryBot.create(:invoice, client: client, status: 'paid')

      session_with_sent_invoice = FactoryBot.create(:client_session, client: client, invoice: sent_invoice, description: "Session with sent invoice")
      session_with_paid_invoice = FactoryBot.create(:client_session, client: client, invoice: paid_invoice, description: "Session with paid invoice")

      visit client_sessions_path

      # Session with sent invoice should not have Edit or Delete buttons
      within("##{dom_id(session_with_sent_invoice)}") do
        expect(page).to have_link("View")
        expect(page).not_to have_link("Edit")
        expect(page).not_to have_button("Delete")
      end

      # Session with paid invoice should not have Edit or Delete buttons
      within("##{dom_id(session_with_paid_invoice)}") do
        expect(page).to have_link("View")
        expect(page).not_to have_link("Edit")
        expect(page).not_to have_button("Delete")
      end
    end

    it "has a link to create a new client session" do
      visit client_sessions_path

      expect(page).to have_link("New Client Session")
    end
  end

  describe "Creating a new client session" do
    it "allows creating a client session with valid information" do
      visit new_client_session_path

      select client.name, from: "Client"
      fill_in "Session Date", with: Date.current.strftime("%d/%m/%Y")
      fill_in "Units", with: "1.5"
      fill_in "Description", with: "Test session description"

      click_button "Create Client session"

      expect(page).to have_content("Client session was successfully created")

      created_session = ClientSession.last
      expect(created_session.client).to eq(client)
      expect(created_session.units).to eq(1.5)
      expect(created_session.description).to eq("Test session description")
      expect(created_session.session_date).to eq(Date.current)
    end

    it "shows validation errors when submitting invalid information", js: true do
      visit new_client_session_path

      # Submit without filling any fields
      click_button "Create Client session"

      # Expect to see validation errors
      expect(page).to have_content("prohibited this record from being saved")
      expect(page).to have_content("Client can't be blank")
      expect(page).to have_content("Session Date can't be blank")
    end

    it "shows validation errors when units is not a positive number", js: true do
      visit new_client_session_path

      select client.name, from: "Client"
      fill_in "Session Date", with: Date.current.strftime("%d/%m/%Y")
      fill_in "Units", with: "-3.0"

      click_button "Create Client session"

      expect(page).to have_content("Units is too low")
    end
  end

  describe "Viewing a client session" do
    let!(:client_session) { FactoryBot.create(:client_session, client: client, units: 1.25, description: "Detailed session notes") }

    it "displays all session details" do
      visit client_session_path(client_session)

      expect(page).to have_content(client.name)
      expect(page).to have_content("1.25")
      expect(page).to have_content("Detailed session notes")
      expect(page).to have_content(client_session.session_date.strftime("%d %B %Y"))
    end

    it "provides action buttons" do
      visit client_session_path(client_session)

      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
      expect(page).to have_link("Back", href: client_sessions_path)
    end
  end

  describe "Editing a client session" do
    let!(:client_session) { FactoryBot.create(:client_session, client: client, units: 1.0, description: "Original description") }

    it "allows updating session information" do
      visit edit_client_session_path(client_session)

      fill_in "Units", with: "2.0"
      fill_in "Description", with: "Updated session description"

      click_button "Update Client session"

      expect(page).to have_content("Client session was successfully updated")

      client_session.reload
      expect(client_session.units).to eq(2.0)
      expect(client_session.description).to eq("Updated session description")
    end

    it "shows validation errors when updating with invalid information", js: true do
      visit edit_client_session_path(client_session)

      fill_in "Units", with: ""

      click_button "Update Client session"

      expect(page).to have_content("prohibited this record from being saved")
      expect(page).to have_content("Units can't be blank")
    end
  end

  describe "Deleting a client session" do
    let!(:client_session) { FactoryBot.create(:client_session, client: client) }

    shared_examples "delete client session" do
      it "allows deletion with confirmation dialog" do
        # Wait for the delete confirmation dialog to appear
        expect(page).to have_css("dialog[open]")
        expect(page).to have_content("Are you sure you want to delete")
        expect(page).to have_content(client_session.summary)

        within("dialog") do
          click_button "Delete"
        end

        expect(page).to have_content("Client session was successfully destroyed")
        expect(ClientSession.exists?(client_session.id)).to be_falsey
      end

      it "allows canceling the delete action" do
        within("dialog") do
          click_button "Cancel"
        end

        # Dialog should close and session should remain unchanged
        expect(page).not_to have_css("dialog[open]")
        expect(ClientSession.exists?(client_session.id)).to be_truthy
      end

      it "allows canceling by clicking outside the dialog" do
        # Wait for the delete confirmation dialog to appear
        expect(page).to have_css("dialog[open]")

        # Click outside the dialog (on the dialog backdrop)
        page.execute_script("document.querySelector('dialog[open]').click()")

        # Dialog should close and session should remain unchanged
        expect(page).not_to have_css("dialog[open]")
        expect(ClientSession.exists?(client_session.id)).to be_truthy
      end

      it "redirects to index page after successful deletion" do
        within("dialog") do
          click_button "Delete"
        end

        # Wait for the redirect to complete
        expect(page).to have_content("Client session was successfully destroyed")
        expect(current_path).to eq(client_sessions_path)
      end
    end

    context "when session is not invoiced" do
      context "when deleting from index page" do
        before do
          visit client_sessions_path

          within("tr##{dom_id(client_session)}") do
            click_button "Delete"
          end
        end

        include_examples "delete client session"
      end

      context "when deleting from show page" do
        before do
          visit client_session_path(client_session)
          click_button "Delete"
        end

        include_examples "delete client session"
      end
    end

    context "when session is invoiced" do
      let!(:invoice) { FactoryBot.create(:invoice, client: client) }

      before do
        client_session.update!(invoice: invoice)
        invoice.update!(status: 'sent')
      end

      it "does not show delete button on index page when session is invoiced and sent" do
        visit client_sessions_path

        within("tr##{dom_id(client_session)}") do
          expect(page).not_to have_button("Delete")
        end
      end

      it "shows modal informing credit note requirement on show page when trying to delete invoiced session", js: true do
        pending "implement credit note logic"

        visit client_session_path(client_session)

        click_button "Delete"

        expect(page).to have_content("Cannot delete session")
        expect(page).to have_content("credit note must be issued")
      end
    end
  end

  describe "Session calculations" do
    let!(:client_session) { FactoryBot.create(:client_session, client: client, units: 1.5) }

    it "displays calculated session fee based on units and unit rate" do
      visit client_sessions_path

      within("##{dom_id(client_session)}") do
        expected_fee = client_session.units * client_session.unit_session_rate
        expect(page).to have_content("£#{sprintf('%.2f', expected_fee)}")
      end
    end

    it "displays unit rate for the session" do
      visit client_sessions_path

      within("##{dom_id(client_session)}") do
        expect(page).to have_content("£#{sprintf('%.2f', client_session.unit_session_rate)}")
      end
    end
  end

  describe "Invoice integration" do
    let!(:client_session1) { FactoryBot.create(:client_session, client: client, units: 1.0) }
    let!(:client_session2) { FactoryBot.create(:client_session, client: client, units: 1.5) }

    context "when sessions are unbilled" do
      it "shows unbilled status" do
        visit client_sessions_path

        within("##{dom_id(client_session1)}") do
          expect(page).to have_content("Unbilled")
        end
      end
    end

    context "when sessions are invoiced" do
      let!(:invoice) { FactoryBot.create(:invoice, client: client, status: 'created') }

      before do
        client_session1.update!(invoice: invoice)
      end

      it "shows invoice status" do
        visit client_sessions_path

        within("##{dom_id(client_session1)}") do
          expect(page).to have_content("Created")
        end
      end

      it "provides link to invoice when session is invoiced" do
        visit client_session_path(client_session1)

        expect(page).to have_link("Invoice ##{invoice.id}")
      end
    end
  end

  describe "Filtering and search" do
    let!(:client2) { FactoryBot.create(:client, name: "Another Client") }
    let!(:session_client1) { FactoryBot.create(:client_session, client: client, description: "Session for client 1") }
    let!(:session_client2) { FactoryBot.create(:client_session, client: client2, description: "Session for client 2") }

    it "displays sessions from all clients by default" do
      visit client_sessions_path

      expect(page).to have_content(client.name)
      expect(page).to have_content(client2.name)
      expect(page).to have_content("Session for client 1")
      expect(page).to have_content("Session for client 2")
    end
  end

  describe "Navigation" do
    it "has proper navigation links" do
      visit client_sessions_path

      expect(page).to have_link("New Client Session", href: new_client_session_path)
    end

    it "can navigate between pages" do
      client_session = FactoryBot.create(:client_session, client: client)

      visit client_sessions_path
      click_link "View"

      expect(page).to have_selector("h1", text: "Session Details")
      expect(current_path).to eq(client_session_path(client_session))

      click_link "Edit"

      expect(page).to have_selector("form[action='#{client_session_path(client_session)}']")
      expect(current_path).to eq(edit_client_session_path(client_session))

      click_link "Back"
      expect(current_path).to eq(client_sessions_path)
    end
  end

  describe "Responsive design and accessibility" do
    let!(:client_session) { FactoryBot.create(:client_session, client: client) }

    it "displays properly on mobile devices", driver: :selenium_chrome_headless_mobile do
      visit client_sessions_path

      expect(page).to have_content("Client Sessions")
      expect(page).to have_content(client.name)
    end

    it "has accessible form labels" do
      visit new_client_session_path

      expect(page).to have_selector("label[for='client_session_client_id']")
      expect(page).to have_selector("label[for='client_session_session_date']")
      expect(page).to have_selector("label[for='client_session_units']")
      expect(page).to have_selector("label[for='client_session_description']")
    end
  end
end
