class MissionsController < ApplicationController
  before_action :set_mission, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize Mission
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    @scope = params[:scope].to_s.strip
    scope = policy_scope(Mission).includes(:client_contact, :region, :specialty, freelancer_profile: :user)
                                 .order(created_at: :desc)
                                 .search(@q)
                                 .with_status(@status)

    if current_user.role_freelance? && @scope.blank? && @status.blank? && @q.blank?
      load_freelance_missions_dashboard
      return
    end

    if current_user.role_freelance? && @scope == "my_missions"
      scope = scope.joins(:freelancer_profile).where(freelancer_profiles: { user_id: current_user.id })
    elsif current_user.role_freelance? && @scope == "library"
      own_mission_ids = Mission.joins(:freelancer_profile).where(freelancer_profiles: { user_id: current_user.id }).select(:id)
      scope = scope.where.not(id: own_mission_ids)
    end

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

  def load_freelance_missions_dashboard
    current_scope = policy_scope(Mission)
      .includes(:region, :client_contact, :specialty, freelancer_profile: :user)
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })

    @current_missions = current_scope
      .where(status: %w[open in_progress])
      .order(created_at: :desc)
      .limit(3)

    @current_missions_count = current_scope.where(status: %w[open in_progress]).count
    @pending_response_count = current_scope.where(status: "open").count
    @accepted_offers_count = current_scope.where(status: "in_progress").count

    @library_missions = policy_scope(Mission)
      .includes(:region, :client_contact, :specialty)
      .where(status: "open")
      .where.not(id: current_scope.select(:id))
      .order(created_at: :desc)
      .limit(3)
  end
end
