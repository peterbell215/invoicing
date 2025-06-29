class MessagesController < ApplicationController
  before_action :set_message, only: [ :show, :edit, :update, :destroy ]

  def index
    @messages = Message.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @message = Message.new
    @clients = Client.where(active: true).order(:name)
  end

  def create
    @message = Message.new(message_params)

    respond_to :html

    if @message.save
      redirect_to messages_path, notice: "Message was successfully created."
    else
      @clients = Client.where(active: true).order(:surname, :given_name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @clients = Client.where(active: true).order(:surname, :given_name)
    @client_ids = @message.clients.pluck(:id)
    @applies_to_all = @message.all_clients
  end

  def update
    respond_to :html

    if @message.update(message_params)
      redirect_to messages_path, notice: "Message was successfully updated."
    else
      @clients = Client.where(active: true).order(:surname, :given_name)
      @selected_client_ids = @message.clients.pluck(:id)
      @applies_to_all = @message.applies_to_all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to messages_path, notice: "Message was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:text, :from_date, :until_date, :all_clients, client_ids: [])
  end
end
