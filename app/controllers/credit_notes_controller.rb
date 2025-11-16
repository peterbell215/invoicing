class CreditNotesController < ApplicationController
  before_action :set_credit_note, only: %i[show edit update destroy]
  before_action :set_invoice, only: %i[new create]

  def show
  end

  def new
    @credit_note = CreditNote.new(invoice: @invoice, amount: @invoice.amount)
  end

  def create
    @credit_note = CreditNote.new(credit_note_params)
    @credit_note.invoice = @invoice

    if @credit_note.save
      redirect_to @credit_note, notice: "Credit note was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @credit_note.created?
      redirect_to @credit_note, alert: "Cannot edit credit note that has been sent."
    end
  end

  def update
    if @credit_note.update(credit_note_params)
      redirect_to @credit_note, notice: "Credit note was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @credit_note.destroy
      redirect_to invoices_path, notice: "Credit note was successfully deleted."
    else
      redirect_to @credit_note, alert: "Cannot delete credit note that has been sent."
    end
  end

  def send_credit_note
    @credit_note = CreditNote.find(params[:id])

    # Attach PDF if it doesn't already exist
    unless @credit_note.pdf.attached?
      pdf_content = generate_credit_note_pdf

      @credit_note.pdf.attach(
        io: StringIO.new(pdf_content),
        filename: "credit_note_#{@credit_note.id}.pdf",
        content_type: "application/pdf"
      )
    end

    # Send the email
    CreditNoteMailer.credit_note_email(@credit_note).deliver_now

    # Mark as sent if not already
    @credit_note.sent! unless @credit_note.sent?

    redirect_to @credit_note, notice: "Credit note was successfully sent."
  end

  private

  def set_credit_note
    @credit_note = CreditNote.find(params[:id])
  end

  def set_invoice
    @invoice = Invoice.find(params[:invoice_id])
  end

  def credit_note_params
    permitted = params.require(:credit_note).permit(:amount, :reason, :date)

    # Convert amount from string to Money if present
    if permitted[:amount].present?
      permitted[:amount] = Money.new((permitted[:amount].to_f * 100).to_i, "GBP")
    end

    permitted
  end

  def generate_credit_note_pdf
    # Get the HTML of the credit note show page
    html = render_to_string template: "credit_notes/show", layout: "pdf", locals: { credit_note: @credit_note }

    # Convert to PDF using Ferrum_pdf
    FerrumPdf.render_pdf(html: html)
  end
end
