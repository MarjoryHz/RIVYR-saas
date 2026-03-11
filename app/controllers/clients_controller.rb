class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Client
    @q = params[:q].to_s.strip
    scope = policy_scope(Client).order(:legal_name).search(@q)
    @clients = paginate(scope)
  end

  def show
    authorize @client
  end

  def new
    @client = Client.new
    authorize @client
  end

  def create
    @client = Client.new(client_params)
    authorize @client

    if @client.save
      redirect_to @client, notice: "Client cree avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @client
  end

  def update
    authorize @client

    if @client.update(client_params)
      redirect_to @client, notice: "Client mis a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @client

    if @client.destroy
      redirect_to clients_path, status: :see_other, notice: "Client supprime avec succes."
    else
      redirect_to @client, alert: "Impossible de supprimer ce client."
    end
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(
      :ownership_type,
      :legal_name,
      :brand_name,
      :sector,
      :website_url,
      :location,
      :company_size,
      :bio,
      :active
    )
  end
end
