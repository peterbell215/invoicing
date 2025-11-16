class CreditNotesController < ApplicationController
  before_action :set_credit_note, only: %i[show edit update destroy]
  before_action :set_invoice, only: %i[new create]

  def show
  end

  def new
    @credit_note = CreditNote.new(
      invoice: @invoice,
      client: @invoice.client,
      payee: @invoice.payee,
      amount: @invoice.amount
    )
  end

  def create
    @credit_note = CreditNote.new(credit_note_params)
    @credit_note.invoice = @invoice
    @credit_note.client = @invoice.client
    @credit_note.payee = @invoice.payee

    if @credit_note.save
      redirect_to @credit_note, notice: "Credit note was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @credit_note.created?
      redirect_to @credit_note, alert: "Cannot edit credit note that has been sent or applied."
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
      redirect_to billings_path, notice: "Credit note was successfully deleted."
    else
      redirect_to @credit_note, alert: "Cannot delete credit note that has been sent or applied."
    end
  end

  def send_credit_note
    @credit_note = CreditNote.find(params[:id])
    
    if @credit_note.created?
      @credit_note.sent!
      redirect_to @credit_note, notice: "Credit note was successfully sent."
    else
      redirect_to @credit_note, alert: "Credit note has already been sent."
    end
  end

  def mark_applied
    @credit_note = CreditNote.find(params[:id])
    
    if @credit_note.sent?
      @credit_note.applied!
      redirect_to @credit_note, notice: "Credit note was successfully marked as applied."
    else
      redirect_to @credit_note, alert: "Credit note must be sent before marking as applied."
    end
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
end

