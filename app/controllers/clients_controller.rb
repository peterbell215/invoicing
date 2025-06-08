class ClientsController < ApplicationController
  before_action :set_client, only: %i[show edit update destroy current_rate]
  before_action :set_payees, only: %i[new edit create update]

  # GET /clients or /clients.json
  def index
    @show_active_only = params[:active_only] == "true"
    @clients = @show_active_only ? Client.active : Client.all
  end

  # GET /clients/1 or /clients/1.json
  def show
  end

  # GET /clients/new
  def new
    @client = Client.new
  end

  # GET /clients/1/edit
  def edit
  end

  # GET /clients/:id/client_rate.json
  def current_rate
    respond_to :json
  end

  # POST /clients or /clients.json
  def create
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save
        format.html { redirect_to @client, notice: "Client was successfully created." }
        format.json { render :show, status: :created, location: @client }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clients/1 or /clients/1.json
  def update
    respond_to do |format|
      if @client.update(client_params)
        format.html { redirect_to @client, notice: "Client was successfully updated." }
        format.json { render :show, status: :ok, location: @client }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/1 or /clients/1.json
  def destroy
    @client.destroy!

    respond_to do |format|
      format.html { redirect_to clients_path, status: :see_other, notice: "Client was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_client
    @client = Client.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def client_params
    params.require(:client).permit(
      :name,
      :email,
      :address1,
      :address2,
      :town,
      :postcode,
      :new_rate,
      :new_rate_from,
      :active,
      :paid_by_id
    )
  end

  # Set available payees for the dropdown
  def set_payees
    @payees = Payee.where(active: true).order(:name)
  end
end
