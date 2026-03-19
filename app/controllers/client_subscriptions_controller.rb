class ClientSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client

  def create
    current_user.client_subscriptions.find_or_create_by!(client: @client)
    redirect_back fallback_location: company_showcase_path(client_id: @client.id), notice: "Vous êtes abonné à cette entreprise."
  end

  def destroy
    current_user.client_subscriptions.where(client: @client).destroy_all
    redirect_back fallback_location: company_showcase_path(client_id: @client.id), notice: "Vous n'êtes plus abonné à cette entreprise."
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end
end
