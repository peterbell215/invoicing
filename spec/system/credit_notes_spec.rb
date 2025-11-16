require 'rails_helper'

RSpec.describe "Credit Notes", type: :system do
  let!(:client) { FactoryBot.create(:client) }
  let!(:invoice) { FactoryBot.create(:invoice, client: client, status: :sent) }

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
      created_invoice = FactoryBot.create(:invoice, client: client, status: :created)

      visit invoices_path

      within("#invoice_#{created_invoice.id}") do
        expect(page).not_to have_link("Issue Credit Note")
      end
    end
  end

  describe "Credit note lifecycle" do
    let!(:credit_note) { FactoryBot.create(:credit_note, invoice_param: invoice, status: :created) }

    it "allows editing a created credit note" do
      visit credit_note_path(credit_note)

      click_link "Edit"

      fill_in "Reason for Credit Note", with: "Updated reason"
      click_button "Update Credit Note"

      expect(page).to have_content("Credit note was successfully updated")
      expect(page).to have_content("Updated reason")
    end

    it "allows sending a created credit note" do
      visit credit_note_path(credit_note)

      click_button "Send Credit Note"

      expect(page).to have_content("Credit note was successfully sent")
      expect(credit_note.reload.status).to eq("sent")
    end

    it "allows deleting a created credit note" do
      visit credit_note_path(credit_note)

      click_button "Delete"

      expect(page).to have_content("Credit note was successfully deleted")
      expect(CreditNote.exists?(credit_note.id)).to be false
    end

    it "prevents editing a sent credit note" do
      credit_note.update(status: :sent)
      visit credit_note_path(credit_note)

      expect(page).not_to have_link("Edit")
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

