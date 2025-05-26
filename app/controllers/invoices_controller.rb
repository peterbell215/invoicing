class InvoicesController < ApplicationController
  before_action :set_client, only: [:new, :create]
  before_action :set_invoice, only: [:show, :mark_paid]
  
  def index
    @invoices = Invoice.all.order(created_at: :desc)
  end
  
  def show
    # @invoice is set by before_action
  end
  
  def new
    @uninvoiced_sessions = @client.client_sessions.where(invoice_id: nil).order(start: :desc)
  end
  
  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.client = @client
    
    if @invoice.save
      # Associate selected sessions with the new invoice
      if params[:session_ids].present?
        @client.client_sessions.where(id: params[:session_ids]).update_all(invoice_id: @invoice.id)
      end
      
      redirect_to @invoice, notice: 'Invoice was successfully generated.'
    else
      @uninvoiced_sessions = @client.client_sessions.where(invoice_id: nil).order(start: :desc)
      render :new, status: :unprocessable_entity
    end
  end
  
  def mark_paid
    @invoice.update(paid: true, paid_date: Date.today)
    redirect_to invoices_path, notice: "Invoice #{@invoice.reference} has been marked as paid."
  end
  
  private
  
  def set_client
    @client = Client.find(params[:client_id])
  end
  
  def set_invoice
    @invoice = Invoice.find(params[:id])
  end
  
  def invoice_params
    params.require(:invoice).permit(:date, :reference)
  end
end
