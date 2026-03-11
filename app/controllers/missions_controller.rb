class MissionsController < ApplicationController
  before_action :set_mission, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize Mission
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = policy_scope(Mission).includes(:client_contact, :region, :specialty, freelancer_profile: :user)
                                 .order(created_at: :desc)
                                 .search(@q)
                                 .with_status(@status)
    @missions = paginate(scope)
  end

  def show
    authorize @mission
  end

  def new
    @mission = Mission.new
    authorize @mission
  end

  def create
    @mission = Mission.new(mission_params)
    authorize @mission

    if @mission.save
      redirect_to @mission, notice: "Mission creee avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @mission
  end

  def update
    authorize @mission

    if @mission.update(mission_params)
      redirect_to @mission, notice: "Mission mise a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @mission

    if @mission.destroy
      redirect_to missions_path, status: :see_other, notice: "Mission supprimee avec succes."
    else
      redirect_to @mission, alert: "Impossible de supprimer cette mission."
    end
  end

  private

  def set_mission
    @mission = Mission.includes(:client_contact, :region, :specialty, freelancer_profile: :user).find(params[:id])
  end

  def set_form_collections
    @client_contacts = if current_user.role_client?
      ClientContact.includes(:client).where(id: current_user.client_contact&.id)
    elsif current_user.role_freelance?
      ClientContact.includes(:client).order(:last_name, :first_name)
    else
      policy_scope(ClientContact).includes(:client).order(:last_name, :first_name)
    end

    @freelancer_profiles = if current_user.role_freelance?
      FreelancerProfile.includes(:user).where(user_id: current_user.id)
    else
      policy_scope(FreelancerProfile).includes(:user).order(:updated_at)
    end
    @regions = Region.order(:name)
    @specialties = Specialty.order(:name)
  end

  def mission_params
    attributes = params.require(:mission).permit(
      :region_id,
      :freelancer_profile_id,
      :client_contact_id,
      :specialty_id,
      :mission_type,
      :title,
      :reference,
      :status,
      :location,
      :contract_signed,
      :opened_at,
      :started_at,
      :closed_at,
      :priority_level,
      :brief_summary,
      :compensation_summary,
      :search_constraints,
      :origin_type
    )

    attributes[:freelancer_profile_id] = current_user.freelancer_profile&.id if current_user.role_freelance?
    attributes[:client_contact_id] = current_user.client_contact&.id if current_user.role_client?

    attributes
  end
end
