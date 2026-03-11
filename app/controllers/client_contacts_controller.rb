class ClientContactsController < ApplicationController
  before_action :set_client_contact, only: [ :show, :edit, :update, :destroy ]
  before_action :set_clients, only: [ :new, :create, :edit, :update ]

  def index
    @q = params[:q].to_s.strip
    scope = ClientContact.includes(:client).order(:last_name, :first_name).search(@q)
    @client_contacts = paginate(scope)
  end

  def show
  end

  def new
    @client_contact = ClientContact.new
  end

  def create
    @client_contact = ClientContact.new(client_contact_params)

    if @client_contact.save
      redirect_to @client_contact, notice: "Contact client cree avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client_contact.update(client_contact_params)
      redirect_to @client_contact, notice: "Contact client mis a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @client_contact.destroy
      redirect_to client_contacts_path, status: :see_other, notice: "Contact client supprime avec succes."
    else
      redirect_to @client_contact, alert: "Impossible de supprimer ce contact client."
    end
  end

  private

  def set_client_contact
    @client_contact = ClientContact.includes(:client).find(params[:id])
  end

  def set_clients
    @clients = Client.order(:legal_name)
  end

  def client_contact_params
    params.require(:client_contact).permit(
      :client_id,
      :first_name,
      :last_name,
      :email,
      :phone,
      :job_title,
      :primary_contact
    )
  end
end
