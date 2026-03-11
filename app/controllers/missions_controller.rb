class MissionsController < ApplicationController
  before_action :set_mission, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = Mission.includes(:client_contact, :region, :specialty, freelancer_profile: :user)
                   .order(created_at: :desc)
                   .search(@q)
                   .with_status(@status)
    @missions = paginate(scope)
  end

  def show
  end

  def new
    @mission = Mission.new
  end

  def create
    @mission = Mission.new(mission_params)

    if @mission.save
      redirect_to @mission, notice: "Mission creee avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @mission.update(mission_params)
      redirect_to @mission, notice: "Mission mise a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
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
    @client_contacts = ClientContact.includes(:client).order(:last_name, :first_name)
    @freelancer_profiles = FreelancerProfile.includes(:user).order(:updated_at)
    @regions = Region.order(:name)
    @specialties = Specialty.order(:name)
  end

  def mission_params
    params.require(:mission).permit(
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
  end
end
