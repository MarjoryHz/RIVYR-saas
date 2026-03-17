class ClientContactsController < ApplicationController
  before_action :set_client_contact, only: [ :show, :edit, :update, :destroy ]
  before_action :set_clients, only: [ :new, :create, :edit, :update ]

  def index
    authorize ClientContact
    @q = params[:q].to_s.strip
    scope = policy_scope(ClientContact).includes(:client).order(:last_name, :first_name).search(@q)
    @client_contacts = paginate(scope)
  end

  def show
    authorize @client_contact
  end

  def new
    @client_contact = ClientContact.new
    authorize @client_contact
  end

  def create
    @client_contact = ClientContact.new(client_contact_params)
    authorize @client_contact
    @client_contact.user_id = current_user.id if current_user&.role_freelance?

    if @client_contact.save
      redirect_to @client_contact, notice: "Contact client créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @client_contact
  end

  def update
    authorize @client_contact

    if @client_contact.update(client_contact_params)
      redirect_to @client_contact, notice: "Contact client mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @client_contact

    if @client_contact.destroy
      redirect_to client_contacts_path, status: :see_other, notice: "Contact client supprimé avec succès."
    else
      redirect_to @client_contact, alert: "Impossible de supprimer ce contact client."
    end
  end

  private

  def set_client_contact
    @client_contact = ClientContact.includes(:client).find(params[:id])
  end

  def set_clients
    @clients = policy_scope(Client).order(:legal_name)
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
