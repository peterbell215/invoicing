class MessagesController < ApplicationController
  before_action :set_message, only: [:show, :edit, :update, :destroy]

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

    respond_to do |format|
      if @message.save
        # Handle client assignments
        if params[:apply_to_all_clients].present?
          @message.apply_to_all_clients
        elsif params[:client_ids].present?
          @message.apply_to_clients(params[:client_ids])
        end

        format.html { redirect_to messages_path, notice: 'Message was successfully created.' }
        format.json { render :show, status: :created, location: @message }
      else
        @clients = Client.where(active: true).order(:surname, :given_name)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @clients = Client.where(active: true).order(:surname, :given_name)
    @selected_client_ids = @message.clients.pluck(:id)
    @applies_to_all = @message.applies_to_all_clients?
  end

  def update
    respond_to do |format|
      if @message.update(message_params)
        # Handle client assignments - first remove all existing assignments
        @message.messages_for_clients.destroy_all

        # Then create new assignments based on form params
        if params[:apply_to_all_clients].present?
          @message.apply_to_all_clients
        elsif params[:client_ids].present?
          @message.apply_to_clients(params[:client_ids])
        end

        format.html { redirect_to messages_path, notice: 'Message was successfully updated.' }
        format.json { render :show, status: :ok, location: @message }
      else
        @clients = Client.where(active: true).order(:surname, :given_name)
        @selected_client_ids = @message.clients.pluck(:id)
        @applies_to_all = @message.applies_to_all_clients?
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to messages_path, notice: 'Message was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:text, :from, :until)
  end
end
