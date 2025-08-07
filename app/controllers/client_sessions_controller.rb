class ClientSessionsController < ApplicationController
  before_action :set_client_session, only: %i[ show edit update destroy ]

  # GET /client_sessions or /client_sessions.json
  def index
    @client_sessions = ClientSession.order(session_date: :asc)
  end

  # GET /client_sessions/1 or /client_sessions/1.json
  def show
  end

  # GET /client_sessions/new
  def new
    @client_session = ClientSession.new
  end

  # GET /client_sessions/1/edit
  def edit
  end

  # POST /client_sessions or /client_sessions.json
  def create
    @client_session = ClientSession.new(client_session_params)

    respond_to :html

    if @client_session.save
      redirect_to @client_session, notice: "Client session was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /client_sessions/1 or /client_sessions/1.json
  def update
    respond_to :html

    if @client_session.update(client_session_params)
      redirect_to @client_session, notice: "Client session was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /client_sessions/1 or /client_sessions/1.json
  def destroy
    @client_session.destroy!

    respond_to :html

    redirect_to client_sessions_path, status: :see_other, notice: "Client session was successfully destroyed."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_client_session
    @client_session = ClientSession.find(params.require(:id))
  end

  # Only allow a list of trusted parameters through.
  def client_session_params
    params.require(:client_session).permit(:client_id, :session_date, :duration, :description)
  end
end
