class PayeesController < ApplicationController
  before_action :set_payee, only: %i[ show edit update destroy ]

  # GET /payees or /payees.json
  def index
    @show_active_only = params[:active_only] == "true"
    @payees = (@show_active_only ? Payee.active : Payee.all).order(:name)
  end

  # GET /payees/1 or /payees/1.json
  def show
  end

  # GET /payees/new
  def new
    @payee = Payee.new
  end

  # GET /payees/1/edit
  def edit
  end

  # POST /payees or /payees.json
  def create
    @payee = Payee.new(payee_params)

    respond_to do |format|
      if @payee.save
        format.html { redirect_to payee_url(@payee), notice: "Payee was successfully created." }
        format.json { render :show, status: :created, location: @payee }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @payee.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /payees/1 or /payees/1.json
  def update
    respond_to do |format|
      if @payee.update(payee_params)
        format.html { redirect_to payee_url(@payee), notice: "Payee was successfully updated." }
        format.json { render :show, status: :ok, location: @payee }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @payee.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /payees/1 or /payees/1.json
  def destroy
    respond_to do |format|
      if @payee.clients.any?
        format.html { redirect_to payees_url, alert: "Cannot delete payee who has associated clients." }
        format.json { render json: { error: "Cannot delete payee who has associated clients" }, status: :unprocessable_content }
      else
        @payee.destroy!
        format.html { redirect_to payees_url, notice: "Payee was successfully destroyed." }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payee
      @payee = Payee.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def payee_params
      params.require(:payee).permit(:organisation, :name, :email, :address1, :address2, :town, :county, :postcode, :phone, :active)
    end
end
