class FreelancerProfilesController < ApplicationController
  before_action :set_freelancer_profile, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize FreelancerProfile
    @q = params[:q].to_s.strip
    @operational_status = params[:operational_status].to_s.strip
    scope = policy_scope(FreelancerProfile).includes(:user, :region, :specialty)
                                           .order(created_at: :desc)
                                           .search(@q)
                                           .with_operational_status(@operational_status)
    @freelancer_profiles = paginate(scope)
  end

  def show
    authorize @freelancer_profile
  end

  def new
    @freelancer_profile = FreelancerProfile.new
    authorize @freelancer_profile
  end

  def create
    @freelancer_profile = FreelancerProfile.new(freelancer_profile_params)
    authorize @freelancer_profile

    if @freelancer_profile.save
      redirect_to @freelancer_profile, notice: "Profil freelancer cree avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @freelancer_profile
  end

  def update
    authorize @freelancer_profile

    if @freelancer_profile.update(freelancer_profile_params)
      redirect_to @freelancer_profile, notice: "Profil freelancer mis a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @freelancer_profile

    if @freelancer_profile.destroy
      redirect_to freelancer_profiles_path, status: :see_other, notice: "Profil freelancer supprime avec succes."
    else
      redirect_to @freelancer_profile, alert: "Impossible de supprimer ce profil freelancer."
    end
  end

  private

  def set_freelancer_profile
    @freelancer_profile = FreelancerProfile.includes(:user, :region, :specialty).find(params[:id])
  end

  def set_form_collections
    @users = if current_user.role_admin?
      User.order(:last_name, :first_name)
    else
      User.where(id: current_user.id)
    end
    @regions = Region.order(:name)
    @specialties = Specialty.order(:name)
  end

  def freelancer_profile_params
    if current_user.role_admin?
      params.require(:freelancer_profile).permit(
        :user_id,
        :region_id,
        :specialty_id,
        :operational_status,
        :availability_status,
        :bio,
        :linkedin_url,
        :website_url,
        :rivyr_score_current,
        :profile_private
      )
    else
      params.require(:freelancer_profile).permit(
        :region_id,
        :specialty_id,
        :operational_status,
        :availability_status,
        :bio,
        :linkedin_url,
        :website_url,
        :rivyr_score_current,
        :profile_private
      )
    end
  end
end
