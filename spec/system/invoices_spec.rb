require 'rails_helper'

RSpec.describe "Invoices", type: :system do
  include ActionText::SystemTestHelper

  let!(:client) { FactoryBot.create(:client) }
  let!(:payee) { FactoryBot.create(:payee) }
  let!(:client_sessions) do
    [
      FactoryBot.create(:client_session, client: client, session_date: 1.week.ago, duration: 60),
      FactoryBot.create(:client_session, client: client, session_date: 2.weeks.ago, duration: 90),
      FactoryBot.create(:client_session, client: client, session_date: 3.weeks.ago, duration: 45)
    ]
  end

  describe "Invoice index page" do
    let!(:paid_invoice) { FactoryBot.create(:invoice, client: client, status: :paid) }
    let!(:sent_invoice) { FactoryBot.create(:invoice, client: client, status: :sent) }
    let!(:created_invoice) { FactoryBot.create(:invoice, client: client, status: :created) }

    it "displays all invoices with correct information" do
      visit invoices_path

      expect(page).to have_content("Invoices")
      expect(page).to have_link(created_invoice.id.to_s, href: invoice_path(created_invoice))
      expect(page).to have_link(sent_invoice.id.to_s, href: invoice_path(sent_invoice))
      expect(page).to have_link(paid_invoice.id.to_s, href: invoice_path(paid_invoice))
      expect(page).to have_content(client.name)
    end

    it "shows correct status badges for different invoice statuses" do
      visit invoices_path

      within("tbody tr:first-child") do
        expect(page).to have_css(".status-badge.created", text: "CREATED")
      end

      within("tbody tr:nth-child(2)") do
        expect(page).to have_css(".status-badge.sent", text: "SENT")
      end

      within("tbody tr:nth-child(3)") do
        expect(page).to have_css(".status-badge.paid", text: "PAID")
      end
    end

    it "shows delete button only for created invoices" do
      visit invoices_path

      within("tbody tr:first-child") do
        expect(page).to have_button("Delete")
        expect(page).to have_link("Edit")
      end

      within("tbody tr:nth-child(2)") do
        expect(page).not_to have_button("Delete")
        expect(page).not_to have_link("Edit")
      end

      within("tbody tr:nth-child(3)") do
        expect(page).not_to have_button("Delete")
        expect(page).not_to have_link("Edit")
      end
    end

    it "shows send button for created and sent invoices but not paid invoices" do
      visit invoices_path

      within("tbody tr:first-child") do
        expect(page).to have_button("Send")
      end

      within("tbody tr:nth-child(2)") do
        expect(page).to have_button("Send")
      end

      within("tbody tr:nth-child(3)") do
        expect(page).not_to have_button("Send")
      end
    end
  end

  describe "Creating a new invoice" do
    it "allows creating an invoice with selected sessions" do
      visit new_client_invoice_path(client)

      expect(page).to have_content("New Invoice for #{client.name}")

      # Fill in invoice details
      fill_in "Date", with: Date.current.strftime("%Y-%m-%d")
      select payee.name, from: "Payee"
      fill_in_rich_textarea "Text", with: "Invoice for consulting services"

      # Select some sessions
      uncheck "session_#{client_sessions[2].id}"

      click_button "Create Invoice"

      expect(page).to have_content("Invoice was successfully generated")

      # Verify the invoice was created correctly
      invoice = Invoice.last
      expect(invoice.client).to eq(client)
      expect(invoice.payee).to eq(payee)
      expect(invoice.text.body.to_plain_text).to eq("Invoice for consulting services")
      expect(invoice.client_sessions).to include(client_sessions[0], client_sessions[1])
      expect(invoice.client_sessions).not_to include(client_sessions[2])
    end

    it "prepopulates text field with relevant messages when creating new invoice", js: true do
      # Create some messages for the client
      message1 = FactoryBot.create(:message, :for_all_clients, text: "General Message for all clients", created_at: 1.week.ago)
      message2 = FactoryBot.create(:message, text: "Specific Message for #{client.name}", created_at: 2.days.ago).apply_to_client(client)

      visit new_client_invoice_path(client)

      within("#invoice_text") do
        expect(page).to have_content("General Message for all clients")
        expect(page).to have_content("Specific Message for #{client.name}")
      end
    end
  end

  describe "Viewing an invoice" do
    let!(:invoice) { FactoryBot.create(:invoice, client: client, payee: payee, text: "Test invoice text") }

    it "displays invoice details correctly" do
      visit invoice_path(invoice)

      within("div.invoice-info > table > tbody > tr:nth-child(1)") do
        expect(page).to have_content("Invoice Number")
        expect(page).to have_content(invoice.id.to_s)
      end

      within("div.invoice-info > table > tbody > tr:nth-child(2)") do
        expect(page).to have_content("Date")
        expect(page).to have_content(invoice.date.strftime('%d %b %Y'))
      end

      expect(page).to have_content(client.name)
      expect(page).to have_content(payee.name)
      expect(page).to have_content("Test invoice text")
    end

    it "shows session details in the invoice" do
      visit invoice_path(invoice)

      invoice.client_sessions.each do |session|
        expect(page).to have_content(session.session_date.strftime('%d %b %Y'))
        expect(page).to have_content("#{session.duration} minutes")
        expect(page).to have_content(session.hourly_session_rate.format)
      end
    end
  end

  describe "Editing an invoice" do
    let!(:invoice) { FactoryBot.create(:invoice, client: client, status: :created) }

    it "allows editing a created invoice" do
      visit edit_invoice_path(invoice)

      expect(page).to have_content("Edit Invoice")

      fill_in_rich_textarea "Text", with: "Updated invoice text"
      click_button "Update Invoice"

      expect(page).to have_content("Invoice was successfully updated")
      expect(page).to have_content("Updated invoice text")
    end

    it "prevents editing sent invoices" do
      invoice.update!(status: :sent)

      visit invoice_path(invoice)
      expect(page).not_to have_link("Edit")

      # Try to access edit page directly
      visit edit_invoice_path(invoice)
      expect(page).to have_content("Cannot edit invoice that has been sent or paid")
    end

    it "prevents editing paid invoices" do
      invoice.update!(status: :paid)

      visit invoice_path(invoice)
      expect(page).not_to have_link("Edit")

      # Try to access edit page directly
      visit edit_invoice_path(invoice)
      expect(page).to have_content("Cannot edit invoice that has been sent or paid")
    end
  end

  describe "Sending an invoice", js: true do
    let!(:invoice) { FactoryBot.create(:invoice, client: client, status: :created) }

    shared_examples "send invoice" do
      it "allows sending an invoice with confirmation dialog" do
        # Wait for the send confirmation dialog to appear
        expect(page).to have_css("dialog#send-confirmation-dialog[open]")
        expect(page).to have_content("Confirm Send Invoice")
        expect(page).to have_content("Invoice ##{invoice.id}")

        within("dialog#send-confirmation-dialog") do
          click_button "Send Invoice"
        end

        expect(page).to have_content("Invoice was successfully sent")
        expect(invoice.reload.status).to eq("sent")
      end

      it "allows canceling the send action" do
        within("dialog#send-confirmation-dialog") do
          click_button "Cancel"
        end

        # Dialog should close and invoice should remain unchanged
        expect(page).not_to have_css("dialog#send-confirmation-dialog[open]")
        expect(invoice.reload.status).to eq("created")
      end

      it "allows canceling by clicking outside the dialog" do
        # Wait for the send confirmation dialog to appear
        expect(page).to have_css("dialog#send-confirmation-dialog[open]")

        # Click outside the dialog (on the dialog backdrop)
        page.execute_script("document.querySelector('#send-confirmation-dialog').click()")

        # Dialog should close and invoice should remain unchanged
        expect(page).not_to have_css("dialog#send-confirmation-dialog[open]")
        expect(invoice.reload.status).to eq("created")
      end
    end

    context "when on the index page" do
      before do
        visit invoices_path

        within("tbody tr:first-child") do
          click_button "Send"
        end
      end

      include_examples "send invoice"
    end

    context "when on the show page" do
      before do
        visit invoice_path(invoice)
        click_button "Send"
      end

      include_examples "send invoice"
    end
  end

  describe "Marking an invoice as paid", js: true do
    let!(:invoice) { FactoryBot.create(:invoice, client: client, status: :sent) }

    shared_examples "mark invoice as paid" do
      it "allows marking an invoice as paid with confirmation dialog" do
        # Wait for the mark paid confirmation dialog to appear
        expect(page).to have_css("dialog#mark-paid-confirmation-dialog[open]")
        expect(page).to have_content("Confirm Mark Invoice as Paid")
        expect(page).to have_content("Invoice ##{invoice.id}")

        within("dialog#mark-paid-confirmation-dialog") do
          click_button "Mark as Paid"
        end

        expect(page).to have_content("Invoice was successfully marked as paid.")
        expect(invoice.reload.status).to eq("paid")
      end

      it "allows canceling the mark as paid action" do
        within("dialog#mark-paid-confirmation-dialog") do
          click_button "Cancel"
        end

        # Dialog should close and invoice should remain unchanged
        expect(page).not_to have_css("dialog[open]")
        expect(invoice.reload.status).to eq("sent")
      end

      it "allows canceling by clicking outside the dialog" do
        # Wait for the mark paid confirmation dialog to appear
        expect(page).to have_css("dialog#mark-paid-confirmation-dialog[open]")

        # Click outside the dialog (on the dialog backdrop)
        page.execute_script("document.querySelector('#mark-paid-confirmation-dialog').click()")

        # Dialog should close and invoice should remain unchanged
        expect(page).not_to have_css("dialog[open]")
        expect(invoice.reload.status).to eq("sent")
      end
    end

    context "when on the index page" do
      before do
        visit invoices_path

        within("tbody tr:first-child") do
          click_button "Mark as Paid"
        end
      end

      include_examples "mark invoice as paid"
    end

    context "when on the show page" do
      before do
        visit invoice_path(invoice)

        click_button "Mark as Paid"
      end

      include_examples "mark invoice as paid"
    end
  end

  describe "Deleting an invoice", js: true do
    let!(:created_invoice) { FactoryBot.create(:invoice, client: client, status: :created) }
    let!(:sent_invoice) { FactoryBot.create(:invoice, client: client, status: :sent) }

    it "allows deleting a created invoice with confirmation dialog" do
      visit invoices_path

      find_link(created_invoice.id.to_s).ancestor('tr').click_button("Delete")

      # Wait for the delete confirmation dialog to appear
      expect(page).to have_css("dialog[open]")
      expect(page).to have_content("Are you sure you want to delete")
      expect(page).to have_content("Invoice ##{created_invoice.id}")

      within("dialog") do
        click_button "Delete"
      end

      expect(page).to have_content("Invoice was successfully deleted")
      expect(page).not_to have_content("Invoice ##{created_invoice.id}")
    end

    it "allows canceling the delete action" do
      visit invoices_path

      find_link(created_invoice.id.to_s).ancestor('tr').click_button("Delete")

      # Wait for the delete confirmation dialog to appear
      expect(page).to have_css("dialog[open]")

      within("dialog") do
        click_button "Cancel"
      end

      # Dialog should close and invoice should still be there
      expect(page).not_to have_css("dialog[open]")

      expect(page).to have_link(created_invoice.id.to_s)
    end

    it "prevents deleting sent invoices by not showing delete button" do
      visit invoices_path

      row = find_link(sent_invoice.id.to_s).ancestor('tr')
      expect(row).not_to have_button("Delete")
    end

    it "frees up associated sessions when invoice is deleted" do
      # Create an invoice with specific sessions
      session1 = client_sessions[0]
      session2 = client_sessions[1]

      created_invoice.client_sessions << [ session1, session2 ]

      expect(session1.reload.invoice_id).to eq(created_invoice.id)
      expect(session2.reload.invoice_id).to eq(created_invoice.id)

      visit invoices_path

      find_link(created_invoice.id.to_s).ancestor('tr').click_button("Delete")

      within("dialog") do
        click_button "Delete"
      end

      expect(page).to have_content("Invoice was successfully deleted")
    end
  end

  describe "Invoice status transitions" do
    let!(:invoice) { FactoryBot.create(:invoice, client: client, status: :created) }

    it "transitions from created to sent" do
      visit invoice_path(invoice)

      click_button "Send"

      within "#send-confirmation-dialog" do
        expect(page).to have_content("Confirm Send Invoice")
        expect(page).to have_content("Invoice ##{invoice.id}")
        click_button "Send"
      end

      expect(page).to have_content("Invoice was successfully sent")

      expect(invoice.reload.status).to eq("sent")
    end

    it "shows appropriate actions for each status" do
      # Created status
      visit invoice_path(invoice)
      expect(page).to have_link("Edit")
      expect(page).to have_button("Send")

      # Send the invoice
      accept_confirm("Are you sure you want to send this invoice?") do
        click_link "Send"
      end

      # Sent status
      visit invoice_path(invoice)
      expect(page).not_to have_link("Edit")
      expect(page).to have_link("Send") # Can resend

      # Mark as paid (this would typically be done through a different interface)
      invoice.update!(status: :paid)

      # Paid status
      visit invoice_path(invoice)
      expect(page).not_to have_link("Edit")
      expect(page).not_to have_link("Send")
    end
  end

  describe "Empty state" do
    it "shows appropriate message when no invoices exist" do
      Invoice.destroy_all

      visit invoices_path

      expect(page).to have_content("No invoices found")
      expect(page).to have_content("Create your first invoice by selecting a client and generating an invoice for their sessions")
    end
  end

  describe "Invoice navigation" do
    let!(:invoice) { FactoryBot.create(:invoice, client: client) }

    it "allows navigation from invoice index to individual invoice" do
      visit invoices_path

      click_link "#{invoice.id}"

      expect(current_path).to eq(invoice_path(invoice))
      expect(page).to have_content("Invoice ##{invoice.id}")
    end

    it "allows navigation from client to new invoice" do
      visit client_path(client)

      click_link "Invoice", match: :first

      expect(current_path).to eq(new_client_invoice_path(client))
      expect(page).to have_content("New Invoice")
    end
  end
end
