class MissionsController < ApplicationController
  before_action :set_mission, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]
  before_action :set_mission, only: [ :toggle_freelance_urgent, :apply ]

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
    @mission ||= Mission.includes(:client_contact, :region, :specialty, freelancer_profile: :user).find(params[:id])
    authorize @mission
  end

  def my_missions
    authorize Mission

    freelancer_profile = current_user.freelancer_profile
    @company_filter = params[:company].to_s.strip
    @region_filter = params[:region].to_s.strip
    @urgent_filter = params[:urgent].to_s.strip
    @amount_filter = params[:amount].to_s.strip

    scope = policy_scope(Mission)
      .includes(:client_contact, :region, :specialty, freelancer_profile: :user, placement: :commission)
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })
      .order(created_at: :desc)

    current_missions_scope = scope.where(status: %w[open in_progress])
    preference_map = if freelancer_profile.present?
      freelancer_profile.freelance_mission_preferences.where(mission_id: current_missions_scope.select(:id)).index_by(&:mission_id)
    else
      {}
    end

    current_missions = current_missions_scope.sort_by do |mission|
      urgent_rank = preference_map[mission.id]&.urgent? ? 0 : 1
      started_on = mission.started_at || mission.opened_at || mission.created_at.to_date
      [ urgent_rank, started_on ]
    end
    load_freelance_navigation_counts(scope)
    @closed_missions = scope.where(status: "closed").limit(6)
    @closed_placements_count = Placement.joins(:mission)
      .merge(scope.where(status: "closed"))
      .count
    @current_missions_count = current_missions.count
    @accepted_offers_count = current_missions_scope.where(status: "in_progress").count
    all_mission_rows = current_missions.map { |mission| build_my_mission_row(mission, preference_map[mission.id]) }
    @company_options = all_mission_rows.map { |row| row[:company_name] }.compact.uniq.sort
    @region_options = all_mission_rows.map { |row| row[:region_name] }.compact.uniq.sort
    @mission_rows = filter_my_mission_rows(all_mission_rows)
    @current_missions = @mission_rows.map { |row| row[:mission] }
    @total_potential_cents = @mission_rows.sum { |row| row[:potential_cents] }
    @average_open_days = if @mission_rows.any?
      (@mission_rows.sum { |row| row[:open_days] } / @mission_rows.size.to_f).round
    else
      0
    end
    @total_sent_candidates = @mission_rows.sum { |row| row[:sent_candidates_count] }
  end

  def pending_missions
    authorize Mission

    freelancer_profile = current_user.freelancer_profile
    return redirect_to my_missions_missions_path, alert: "Profil freelance introuvable." if freelancer_profile.blank?

    @company_filter = params[:company].to_s.strip
    @region_filter = params[:region].to_s.strip
    @amount_filter = params[:amount].to_s.strip

    assigned_scope = policy_scope(Mission)
      .includes(:client_contact, :region, :specialty, freelancer_profile: :user, placement: :commission)
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })
      .order(created_at: :desc)
    load_freelance_navigation_counts(assigned_scope)

    applications = freelancer_profile.freelance_mission_applications
      .pending_validation
      .includes(mission: [ :region, :specialty, { client_contact: :client }, { placement: :commission } ])
      .order(applied_at: :desc, created_at: :desc)

    all_application_rows = applications.map { |application| build_pending_mission_row(application) }
    @company_options = all_application_rows.map { |row| row[:company_name] }.compact.uniq.sort
    @region_options = all_application_rows.map { |row| row[:region_name] }.compact.uniq.sort
    @pending_mission_rows = filter_pending_mission_rows(all_application_rows)
    @pending_missions_count = @pending_mission_rows.size
    @pending_total_potential_cents = @pending_mission_rows.sum { |row| row[:potential_cents] }
    @pending_average_days = if @pending_mission_rows.any?
      (@pending_mission_rows.sum { |row| row[:waiting_days] } / @pending_mission_rows.size.to_f).round
    else
      0
    end
    @pending_total_candidates = @pending_mission_rows.sum { |row| row[:sent_candidates_count] }
  end

  def apply
    authorize @mission, :apply?

    freelancer_profile = current_user.freelancer_profile
    return redirect_to missions_path(scope: "library", status: "open"), alert: "Profil freelance introuvable." if freelancer_profile.blank?

    application = FreelanceMissionApplication.find_or_initialize_by(
      freelancer_profile: freelancer_profile,
      mission: @mission
    )
    application.status ||= "applied"
    application.applied_at ||= Time.current
    application.save!

    redirect_to pending_missions_missions_path, notice: "Mission ajoutée à vos validations en attente."
  end

  def toggle_freelance_urgent
    authorize @mission, :show?

    freelancer_profile = current_user.freelancer_profile
    return redirect_to my_missions_missions_path, alert: "Profil freelance introuvable." if freelancer_profile.blank?

    preference = FreelanceMissionPreference.find_or_initialize_by(
      freelancer_profile: freelancer_profile,
      mission: @mission
    )

    preference.urgent = ActiveModel::Type::Boolean.new.cast(params[:urgent])
    preference.save!

    redirect_to my_missions_missions_path, notice: "Priorité mise à jour."
  end

  def new
    @mission = Mission.new
    authorize @mission
  end

  def create
    @mission = Mission.new(mission_params)
    authorize @mission

    if @mission.save
      redirect_to @mission, notice: "Mission créée avec succès."
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
      redirect_target = params[:return_to].presence
      redirect_to redirect_target || @mission, notice: "Mission mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @mission

    if @mission.destroy
      redirect_to missions_path, status: :see_other, notice: "Mission supprimée avec succès."
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

  def build_my_mission_row(mission, preference = nil)
    seed = mission.reference.to_s.hash.abs
    actual_commission_cents = mission.placement&.commission&.freelancer_share_cents
    fallback_potential_cents = (3_000 + (seed % 6_000)) * 100
    started_on = mission.started_at || mission.opened_at || mission.created_at.to_date
    open_days = [ (Date.current - started_on).to_i, 0 ].max
    sent_candidates_count = 3 + (seed % 8)

    open_days_tone =
      if open_days > 45
        "text-error"
      elsif open_days >= 31
        "text-[#ef8a73]"
      elsif open_days >= 21 && sent_candidates_count < 3
        "text-[#ef8a73]"
      else
        "text-base-content/55"
      end

    client_interview_step = sent_candidates_count.positive?
    recruited_step = mission.placement&.hired_at.present?
    validated_step = recruited_step && mission.status_in_progress?

    {
      mission: mission,
      potential_cents: actual_commission_cents.presence || fallback_potential_cents,
      open_days: open_days,
      open_days_tone: open_days_tone,
      sent_candidates_count: sent_candidates_count,
      urgent: preference&.urgent? || false,
      client_contact_name: [ mission.client_contact.first_name, mission.client_contact.last_name ].compact.join(" "),
      company_name: mission.client_contact.client.brand_name.presence || mission.client_contact.client.legal_name,
      company_initials: mission.client_contact.client.brand_name.to_s.first(1).presence || mission.client_contact.client.legal_name.to_s.first(1).presence || "R",
      company_logo: mission.client_contact.client.logo,
      region_name: mission.region&.name,
      recruitment_steps: [
        { label: "Entretien client", done: client_interview_step },
        { label: "Recruté", done: recruited_step },
        { label: "Validé", done: validated_step }
      ]
    }
  end

  def filter_my_mission_rows(rows)
    rows.select do |row|
      matches_company = @company_filter.blank? || row[:company_name] == @company_filter
      matches_region = @region_filter.blank? || row[:region_name] == @region_filter
      matches_urgent =
        case @urgent_filter
        when "urgent" then row[:urgent]
        when "normal" then !row[:urgent]
        else true
        end
      matches_amount =
        case @amount_filter
        when "under_5000" then row[:potential_cents] < 500_000
        when "5000_10000" then row[:potential_cents] >= 500_000 && row[:potential_cents] <= 1_000_000
        when "10000_20000" then row[:potential_cents] > 1_000_000 && row[:potential_cents] <= 2_000_000
        when "over_20000" then row[:potential_cents] > 2_000_000
        else true
        end

      matches_company && matches_region && matches_urgent && matches_amount
    end
  end

  def load_freelance_navigation_counts(scope)
    freelancer_profile = current_user.freelancer_profile

    @current_missions_count = scope.where(status: %w[open in_progress]).count
    @pending_validation_count = if freelancer_profile.present?
      freelancer_profile.freelance_mission_applications.pending_validation.count
    else
      0
    end
    @closed_missions_count = scope.where(status: "closed").count
  end

  def build_pending_mission_row(application)
    mission = application.mission
    seed = mission.reference.to_s.hash.abs
    actual_commission_cents = mission.placement&.commission&.freelancer_share_cents
    fallback_potential_cents = (3_000 + (seed % 6_000)) * 100
    applied_at = application.applied_at || application.created_at
    waiting_days = [ (Date.current - applied_at.to_date).to_i, 0 ].max
    sent_candidates_count = 1 + (seed % 5)

    {
      application: application,
      mission: mission,
      potential_cents: actual_commission_cents.presence || fallback_potential_cents,
      waiting_days: waiting_days,
      sent_candidates_count: sent_candidates_count,
      client_contact_name: [ mission.client_contact.first_name, mission.client_contact.last_name ].compact.join(" "),
      company_name: mission.client_contact.client.brand_name.presence || mission.client_contact.client.legal_name,
      company_logo: mission.client_contact.client.logo,
      region_name: mission.region&.name,
      status_label: application.status_client_review? ? "Chez le client" : "En attente d’envoi"
    }
  end

  def filter_pending_mission_rows(rows)
    rows.select do |row|
      matches_company = @company_filter.blank? || row[:company_name] == @company_filter
      matches_region = @region_filter.blank? || row[:region_name] == @region_filter
      matches_amount = if @amount_filter.blank?
        true
      else
        amount_cents = row[:potential_cents]

        case @amount_filter
        when "under_5000"
          amount_cents < 500_000
        when "5000_10000"
          amount_cents >= 500_000 && amount_cents <= 1_000_000
        when "10000_20000"
          amount_cents > 1_000_000 && amount_cents <= 2_000_000
        when "over_20000"
          amount_cents > 2_000_000
        else
          true
        end
      end

      matches_company && matches_region && matches_amount
    end
  end
end
