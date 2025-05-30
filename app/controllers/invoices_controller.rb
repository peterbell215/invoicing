class InvoicesController < ApplicationController
  before_action :set_client, only: [:new, :create]
  before_action :set_invoice_and_client, only: [:show, :mark_paid, :edit, :update]
  
  def index
    @invoices = Invoice.all.order(created_at: :desc)
  end
  
  def show
    # @invoice is set by before_action
  end
  
  def new
    @available_sessions = @client.client_sessions.where(invoice_id: nil).order(start: :desc)
  end
  
  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.client = @client
    
    if @invoice.save
      # Associate selected sessions with the new invoice
      if params[:session_ids].present?
        @client.client_sessions.where(id: params[:client_session_ids]).update_all(invoice_id: @invoice.id)
      end
      
      redirect_to @invoice, notice: 'Invoice was successfully generated.'
    else
      @uninvoiced_sessions = @client.client_sessions.where(invoice_id: nil).order(start: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Redirect if invoice is not editable
    unless @invoice.created?
      redirect_to invoice_path(@invoice), alert: "Cannot edit invoice that has been sent or paid."
      return
    end
    
    # Get available sessions (uninvoiced or belonging to this invoice)
    @available_sessions = @client.client_sessions.where("invoice_id IS NULL OR invoice_id = ?", @invoice.id).order(start: :asc)
  end

  def update
    @invoice = Invoice.find(params[:id])
    @client = @invoice.client
    
    client_session_ids = invoice_params[:client_session_ids].reject(&:blank?).map(&:to_i)
    
    if @invoice.update(invoice_params.except(:client_session_ids))
      @invoice.update_client_sessions(client_session_ids)
      redirect_to invoice_path(@invoice), notice: "Invoice was successfully updated."
    else
      @available_sessions = @client.client_sessions
                                  .where("invoice_id IS NULL OR invoice_id = ?", @invoice.id)
                                  .order(date: :desc)
      render :edit, status: :unprocessable_entity
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
  
  def set_invoice_and_client
    @invoice = Invoice.find(params[:id])
    @client = @invoice.client
  end
  
  def invoice_params
    params.require(:invoice).permit(:date, :amount, client_session_ids: [])
  end
end
