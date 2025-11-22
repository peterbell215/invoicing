require 'rails_helper'

RSpec.describe "Credit Notes", type: :system do
  let!(:invoice) { create(:invoice_with_client_sessions).tap { |invoice| invoice.update!(status: :sent) } }

  describe "Creating a credit note" do
    it "allows creating a credit note for a sent invoice" do
      visit invoices_path

      within("#invoice_#{invoice.id}") do
        click_link "Issue Credit Note"
      end

      expect(page).to have_content("Issue Credit Note")
      expect(page).to have_content("Invoice ##{invoice.id}")

      fill_in "Credit Amount (£)", with: "25.00"
      fill_in "Reason for Credit Note", with: "Customer requested partial refund"
      click_button "Create Credit Note"

      expect(page).to have_content("Credit note was successfully created")
      expect(page).to have_content("CREDIT NOTE")
      expect(page).to have_content("Customer requested partial refund")
    end

    it "prevents creating a credit note with amount exceeding invoice amount" do
      visit new_invoice_credit_note_path(invoice)

      fill_in "Credit Amount (£)", with: (invoice.amount.to_f + 10).to_s
      fill_in "Reason for Credit Note", with: "Test reason"
      click_button "Create Credit Note"

      expect(page).to have_content("cannot exceed invoice amount")
    end

    it "prevents creating a credit note for a created invoice" do
      created_invoice = FactoryBot.create(:invoice, status: :created)

      visit invoices_path

      within("#invoice_#{created_invoice.id}") do
        expect(page).not_to have_link("Issue Credit Note")
      end
    end
  end

  describe "Credit note lifecycle" do
    let!(:credit_note) { FactoryBot.create(:credit_note, invoice: invoice, status: :created) }

    it "allows editing a created credit note" do
      visit credit_note_path(credit_note)

      click_link "Edit"

      fill_in "Reason for Credit Note", with: "Updated reason"
      click_button "Update Credit Note"

      expect(page).to have_content("Credit note was successfully updated")
      expect(page).to have_content("Updated reason")
    end

    it "allows deleting a created credit note", js: true do
      visit credit_note_path(credit_note)

      # Trigger the delete confirmation dialog
      click_button "Delete"

      # Wait for the delete confirmation dialog to appear
      expect(page).to have_css("dialog[open]")
      expect(page).to have_content("Are you sure you want to delete")

      within("dialog") do
        click_button "Delete"
      end

      expect(page).to have_content("Credit note was successfully deleted")
      expect(CreditNote.exists?(credit_note.id)).to be false
    end

    it "prevents editing a sent credit note" do
      credit_note.update!(status: :sent)
      visit credit_note_path(credit_note)

      expect(page).not_to have_link("Edit")
    end
  end

  describe "Sending a credit note", js: true do
    let!(:credit_note) { FactoryBot.create(:credit_note, invoice: invoice, status: :created) }

    # Clear deliveries before the test
    before do
      ActionMailer::Base.deliveries.clear
    end

    shared_examples "send credit note" do
      it "allows sending a credit note with confirmation dialog" do
        # Wait for the send confirmation dialog to appear
        expect(page).to have_css("dialog#send-credit-note-confirmation-dialog[open]")
        expect(page).to have_content("Confirm Send Credit Note")
        expect(page).to have_content("Credit Note ##{credit_note.id}")

        within("dialog#send-credit-note-confirmation-dialog") do
          click_button "Send Credit Note"
        end

        expect(page).to have_content("Credit note was successfully sent")
        expect(credit_note.reload.status).to eq("sent")

        # Check that an email was sent
        expect(ActionMailer::Base.deliveries.count).to eq(1)

        # Access the sent email
        email = ActionMailer::Base.deliveries.last

        # Make assertions about the email
        expect(email.to).to include(invoice.client.email)
        expect(email.subject).to include("Credit Note ##{credit_note.id}")
      end

      it "allows canceling the send action" do
        within("dialog#send-credit-note-confirmation-dialog") do
          click_button "Cancel"
        end

        # Dialog should close and credit note should remain unchanged
        expect(page).not_to have_css("dialog#send-credit-note-confirmation-dialog[open]")
        expect(credit_note.reload.status).to eq("created")

        # Check that no email was sent
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end

      it "allows canceling by clicking outside the dialog" do
        # Wait for the send confirmation dialog to appear
        expect(page).to have_css("dialog#send-credit-note-confirmation-dialog[open]")

        # Click outside the dialog (on the dialog backdrop)
        page.execute_script("document.querySelector('#send-credit-note-confirmation-dialog').click()")

        # Dialog should close and credit note should remain unchanged
        expect(page).not_to have_css("dialog#send-credit-note-confirmation-dialog[open]")
        expect(credit_note.reload.status).to eq("created")

        # Check that no email was sent
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    context "when on the index page" do
      before do
        visit invoices_path

        within("#credit_note_#{credit_note.id}") do
          click_button "Send"
        end
      end

      include_examples "send credit note"
    end

    context "when on the show page" do
      before do
        visit credit_note_path(credit_note)
        click_button "Send Credit Note"
      end

      include_examples "send credit note"
    end
  end

  describe "Resending a credit note", js: true do
    let!(:credit_note) { FactoryBot.create(:credit_note, invoice: invoice, status: :sent) }

    # Clear deliveries before the test
    before do
      ActionMailer::Base.deliveries.clear
    end

    it "allows resending a sent credit note from show page" do
      visit credit_note_path(credit_note)

      # Should still show the send button for resending
      expect(page).to have_button("Send Credit Note")

      click_button "Send Credit Note"

      # Wait for the send confirmation dialog to appear
      expect(page).to have_css("dialog#send-credit-note-confirmation-dialog[open]")

      within("dialog#send-credit-note-confirmation-dialog") do
        click_button "Send Credit Note"
      end

      expect(page).to have_content("Credit note was successfully sent")
      expect(credit_note.reload.status).to eq("sent")

      # Check that an email was sent
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "allows resending a sent credit note from index page" do
      visit invoices_path

      within("#credit_note_#{credit_note.id}") do
        expect(page).to have_button("Send")
        click_button "Send"
      end

      # Wait for the send confirmation dialog to appear
      expect(page).to have_css("dialog#send-credit-note-confirmation-dialog[open]")

      within("dialog#send-credit-note-confirmation-dialog") do
        click_button "Send Credit Note"
      end

      expect(page).to have_content("Credit note was successfully sent")
      expect(credit_note.reload.status).to eq("sent")

      # Check that an email was sent
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end

  describe "Invoices index" do
    let!(:credit_note) { FactoryBot.create(:credit_note, invoice_param: invoice) }

    it "displays invoices and their credit notes" do
      visit invoices_path

      expect(page).to have_content("Invoices")
      expect(page).to have_selector("#invoice_#{invoice.id}")
      expect(page).to have_selector("#credit_note_#{credit_note.id}")

      # Credit note should appear below its invoice
      invoice_row = find("#invoice_#{invoice.id}")
      credit_note_row = find("#credit_note_#{credit_note.id}")

      expect(credit_note_row).to have_css(".billing-type-badge.credit-note")
    end
  end
end
