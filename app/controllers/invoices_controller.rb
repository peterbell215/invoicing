class InvoicesController < ApplicationController
  before_action :set_client, only: [ :new ]
  before_action :set_invoice_and_client, only: [ :show, :mark_paid, :edit, :update, :send_invoice, :destroy ]
  before_action :set_available_payees, only: [ :new, :edit, :create, :update ]

  def index
    @invoices = Invoice.all.order(created_at: :desc)
  end

  def show
    # @invoice is set by before_action
  end

  def new
    @invoice = Invoice.new(client: @client)
    # If client has a default payee, set it on the invoice
    @invoice.payee = @client.paid_by if @client.paid_by.present?
    @available_sessions = @client.client_sessions.where(invoice_id: nil).order(session_date: :desc)
  end

  def create
    @invoice = Invoice.new(invoice_params)

    if @invoice.save
      # Associate selected sessions with the new invoice
      if params[:session_ids].present?
        @client.client_sessions.where(id: params[:client_session_ids]).update_all(invoice_id: @invoice.id)
      end

      redirect_to @invoice, notice: "Invoice was successfully generated."
    else
      @client = Client.find(invoice_params[:client_id])
      @uninvoiced_sessions = @client.client_sessions.where(invoice_id: nil).order(session_date: :desc)
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
    @available_sessions = @client.client_sessions.where("invoice_id IS NULL OR invoice_id = ?", @invoice.id).order(session_date: :asc)
  end

  def update
    @invoice = Invoice.find(params[:id])
    @client = @invoice.client

    if @invoice.update(invoice_params)
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

  def send_invoice
    # Check if PDF is already attached
    unless @invoice.pdf.attached?
      # Generate PDF using Grover
      pdf_content = generate_invoice_pdf

      # Attach the PDF to the invoice
      @invoice.pdf.attach(
        io: StringIO.new(pdf_content),
        filename: "invoice_#{@invoice.id}.pdf",
        content_type: "application/pdf"
      )
    end

    # Send the email
    InvoiceMailer.invoice_email(@invoice).deliver_now

    # Mark the invoice as sent
    @invoice.sent! unless @invoice.sent? || @invoice.paid?

    redirect_to @invoice, notice: "Invoice was successfully sent."
  end

  def destroy
    # Only allow deletion if invoice can be deleted
    if @invoice.destroy
      # Delete the invoice
      redirect_to invoices_path, notice: "Invoice was successfully deleted."
    else
      redirect_to invoices_path, alert: "Cannot delete invoice that has been sent or paid."
    end
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
    params.require(:invoice).permit(:date, :amount, :client_id, :payee_id, :text, client_session_ids: [])
  end

  def generate_invoice_pdf
    # Get the HTML of the invoice show page
    html = render_to_string template: "invoices/show", layout: "pdf", locals: { invoice: @invoice }

    # Convert to PDF using Ferrum_pdf
    FerrumPdf.render_pdf(html: html)
  end

  def set_available_payees
    @available_payees = Payee.where(active: true).order(:name)
  end
end
