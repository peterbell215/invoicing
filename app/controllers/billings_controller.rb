class BillingsController < ApplicationController
  def index
    # Get all invoices with their associated credit notes
    @invoices = Invoice.includes(:client, :payee, :credit_notes).order(date: :desc, id: :desc)
  end
end

