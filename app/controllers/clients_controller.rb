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

  # POST /clients or /clients.json
  def create
    @client = Client.new(client_params)

    respond_to :html

    if @client.save
      redirect_to @client, notice: "Client was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /clients/1 or /clients/1.json
  def update
    respond_to :html

    if @client.update(client_params)
      redirect_to @client, notice: "Client was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /clients/1 or /clients/1.json
  def destroy
    respond_to :html

    if @client.destroy
      redirect_to clients_path, status: :see_other, notice: "Client was successfully destroyed."
    else
      redirect_to @client, status: :unprocessable_content, alert: "Client could not be destroyed. Please check if there are any associated records."
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
      :paid_by_id,
      :payee_reference
    )
  end

  # Set available payees for the dropdown
  def set_payees
    @payees = Payee.where(active: true).order(:name)
  end
end
