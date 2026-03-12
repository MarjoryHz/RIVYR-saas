class MissionsController < ApplicationController
  helper_method :mission_company_segment, :mission_company_masked, :mission_available_since_label, :mission_score_for, :mission_score_tone_class, :mission_score_breakdown_for, :mission_level_for, :mission_pitch_points, :mission_origin_badge, :favorite_mission?, :mission_approx_fee_label, :mission_client_insight, :mission_client_label, :mission_positionings_label, :mission_fee_label, :mission_fee_breakdown_for, :format_amount

  before_action :set_mission, only: [ :show, :edit, :update, :destroy, :toggle_favorite ]
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
      scope = library_scope.search(@q).with_status(@status).order(created_at: :desc)
    end

    @missions = paginate(scope)
  end

  def library
    authorize Mission
    return redirect_to missions_path, alert: "La bibliotheque de missions est reservee aux freelances." unless current_user.role_freelance?

    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    @specialty_id = params[:specialty_id].to_s.strip
    @published_since = params[:published_since].to_s.strip
    @origin_badge = params[:origin_badge].to_s.strip
    @profile_level = params[:profile_level].to_s.strip
    @location = params[:location].to_s.strip
    @only_favorites = params[:only_favorites].to_s == "1"
    freelance_profile = current_user.freelancer_profile

    base_scope = library_scope
      .includes(:client_contact, :region, :specialty, :placement)
      .where.not(reference: "MIS-2026-019")
      .order(created_at: :desc)
      .then { |scope| apply_library_filters(scope) }

    candidate_missions = base_scope.to_a
    candidate_missions = fallback_library_missions if candidate_missions.empty?
    candidate_missions = candidate_missions.select { |mission| favorite_mission_ids.include?(mission.id) } if @only_favorites

    @client_insights = build_client_insights(candidate_missions.map { |mission| mission.client_contact.client_id }.uniq)
    recruited_specialty_ids = recruited_specialty_ids_for_year(freelance_profile)
    @mission_scores, @mission_score_details = build_library_score_data(candidate_missions, freelance_profile, recruited_specialty_ids)

    sorted_library = sort_missions_by_score(candidate_missions)
    @suggested_missions = sorted_library.first(4)

    @opportunities_count = candidate_missions.size
    @library_missions_available = paginate_array(sorted_library, per_page: 12)
  end

  def toggle_favorite
    authorize @mission, :show?

    ids = favorite_mission_ids
    if ids.include?(@mission.id)
      ids.delete(@mission.id)
    else
      ids << @mission.id
    end
    session[:favorite_library_mission_ids] = ids.uniq

    redirect_to params[:return_to].presence || library_missions_path(status: "open")
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

    @library_missions = library_scope
      .includes(:region, :client_contact, :specialty)
      .order(created_at: :desc)
      .limit(3)
  end

  def library_scope
    MissionPolicy::Scope.new(current_user, Mission).resolve_for_library
  end

  def mission_company_segment(mission)
    company_size = mission.client_contact.client.company_size.to_s.downcase
    numeric_size = company_size[/\d+/]&.to_i

    return "PME" if numeric_size.present? && numeric_size < 200
    return "ETI" if numeric_size.present? && numeric_size <= 500
    return "Grand compte" if numeric_size.present?
    return "PME" if company_size.include?("pme")
    return "ETI" if company_size.include?("eti")
    return "Grand compte" if company_size.include?("grand")

    "PME"
  end

  def mission_available_since_label(mission)
    started_at = mission.opened_at || mission.created_at&.to_date
    return "Date a confirmer" if started_at.blank?

    "#{helpers.time_ago_in_words(started_at).sub(/^about /, "")} ago"
  end

  def mission_company_masked(mission)
    "#{mission_company_segment(mission)} ******"
  end

  def mission_score_for(mission)
    @mission_scores&.fetch(mission.id, 0) || 0
  end

  def mission_score_breakdown_for(mission)
    @mission_score_details&.fetch(mission.id, default_score_breakdown)
  end

  def mission_score_tone_class(mission)
    score = mission_score_for(mission)
    return "text-[#7f2f2a]" if score >= 80
    return "text-[#a24a3d]" if score >= 60
    return "text-[#c97760]" if score >= 40

    "text-[#e9b8a7]"
  end

  def mission_approx_fee_label(mission)
    mission_fee_label(mission)
  end

  def mission_client_insight(mission)
    @client_insights&.fetch(mission.client_contact.client_id, default_client_insight)
  end

  def mission_client_label(mission)
    insight = mission_client_insight(mission)
    insight[:known] ? "Client connu Rivyr" : "Nouveau client Rivyr"
  end

  def mission_positionings_label(mission)
    count = mission.placement.present? ? 1 : 0
    return "Aucun freelance positionne" if count.zero?
    return "1 freelance deja positionne" if count == 1

    "#{count} freelances deja positionnes"
  end

  def mission_fee_label(mission)
    breakdown = mission_fee_breakdown_for(mission)
    return "Fee a estimer" if breakdown[:fee_amount].zero?

    "Fee #{format_amount(breakdown[:fee_amount])}EUR"
  end

  def mission_fee_breakdown_for(mission)
    salary = mission_target_salary_average(mission)
    contract_rate = mission_contract_fee_rate(mission)
    freelance_rate = mission_freelance_share_rate
    gross_fee = (salary * contract_rate).round
    fee_amount = (gross_fee * freelance_rate).round

    {
      salary_average: salary,
      contract_rate: contract_rate,
      freelance_rate: freelance_rate,
      gross_fee: gross_fee,
      fee_amount: fee_amount
    }
  end

  def favorite_mission?(mission)
    favorite_mission_ids.include?(mission.id)
  end

  def recruited_specialty_ids_for_year(freelance_profile)
    return [] if freelance_profile.blank?

    Placement
      .joins(:mission)
      .where(missions: { freelancer_profile_id: freelance_profile.id })
      .where(hired_at: Date.current.beginning_of_year..Date.current.end_of_year)
      .distinct
      .pluck("missions.specialty_id")
  end

  def build_library_score_data(missions, freelance_profile, recruited_specialty_ids)
    scores = {}
    details = {}

    missions.each do |mission|
      specialty_points = 0
      region_points = 0
      recruited_points = 0

      if freelance_profile.present?
        specialty_points = 35 if mission.specialty_id == freelance_profile.specialty_id
        region_points = 20 if mission.region_id == freelance_profile.region_id
      end
      recruited_points = 10 if recruited_specialty_ids.include?(mission.specialty_id)
      priority_points = priority_bonus(mission.priority_level)
      recency_points = recency_bonus(mission.opened_at)
      rivyr_points = mission.origin_type == "rivyr" ? 5 : 0

      total = specialty_points + region_points + recruited_points + priority_points + recency_points + rivyr_points
      total = total.clamp(0, 100)

      scores[mission.id] = total
      details[mission.id] = {
        specialty: specialty_points,
        region: region_points,
        recruited_same_type: recruited_points,
        priority: priority_points,
        recency: recency_points,
        rivyr_origin: rivyr_points,
        total: total
      }
    end

    [ scores, details ]
  end

  def sort_missions_by_score(missions)
    missions.sort_by { |mission| [ -mission_score_for(mission), -(mission.opened_at || Date.new(1900, 1, 1)).jd ] }
  end

  def paginate_array(records, per_page: 20)
    total_count = records.count
    total_pages = (total_count / per_page.to_f).ceil
    total_pages = 1 if total_pages.zero?

    page = params[:page].to_i
    page = 1 if page < 1
    page = total_pages if page > total_pages

    @page = page
    @per_page = per_page
    @total_pages = total_pages
    @total_count = total_count

    records.slice((page - 1) * per_page, per_page) || []
  end

  def fallback_library_missions
    own_profile_id = current_user.freelancer_profile&.id

    Mission
      .includes(:client_contact, :region, :specialty, :placement)
      .where(status: "open")
      .where.not(reference: "MIS-2026-019")
      .where.not(freelancer_profile_id: own_profile_id)
      .then { |scope| apply_library_filters(scope) }
      .order(created_at: :desc)
      .to_a
  end

  def apply_library_filters(scope)
    filtered = scope.left_joins(:region).search(@q).with_status(@status)
    filtered = filtered.where(specialty_id: @specialty_id) if @specialty_id.present?
    filtered = filtered.where("missions.location ILIKE :location OR regions.name ILIKE :location", location: "%#{@location}%") if @location.present?
    filtered = filtered.where(origin_type: @origin_badge) if @origin_badge.present?

    if @published_since.present?
      days = @published_since.to_i
      filtered = filtered.where("missions.opened_at >= ?", Date.current - days.days) if days.positive?
    end

    if @profile_level.present?
      level_pattern = level_patterns[@profile_level]
      filtered = filtered.where(level_pattern) if level_pattern.present?
    end
    filtered
  end

  def level_patterns
    {
      "technicien" => "missions.title ILIKE '%technicien%' OR missions.title ILIKE '%ingenieur%' OR missions.title ILIKE '%specialiste%'",
      "responsable" => "missions.title ILIKE '%responsable%' OR missions.title ILIKE '%manager%'",
      "direction" => "missions.title ILIKE '%directeur%' OR missions.title ILIKE '%head%'",
      "executive" => "missions.title ILIKE '%executive%' OR missions.title ILIKE '%ceo%' OR missions.title ILIKE '%cfo%' OR missions.title ILIKE '%coo%' OR missions.title ILIKE '%cto%' OR missions.title ILIKE '%chief%' OR missions.title ILIKE '%vp%'"
    }
  end

  def priority_bonus(priority_level)
    case priority_level.to_s.downcase
    when "critical" then 12
    when "high" then 8
    when "medium" then 4
    else 0
    end
  end

  def recency_bonus(opened_at)
    return 0 if opened_at.blank?

    days = (Date.current - opened_at).to_i
    return 10 if days <= 7
    return 6 if days <= 30
    return 3 if days <= 60

    0
  end

  def default_score_breakdown
    {
      specialty: 0,
      region: 0,
      recruited_same_type: 0,
      priority: 0,
      recency: 0,
      rivyr_origin: 0,
      total: 0
    }
  end

  def mission_level_for(mission)
    title = mission.title.to_s.downcase
    return "Executive" if title.match?(/executive|ceo|cfo|coo|cto|chief|vp/)
    return "Direction" if title.match?(/directeur|head/)
    return "Responsable" if title.match?(/responsable|manager/)
    return "Technicien" if title.match?(/technicien|ingenieur|specialiste/)

    "Responsable"
  end

  def mission_pitch_points(mission)
    [
      "Contexte: #{truncate_sentence(mission.brief_summary, fallback: "enjeu de structuration avec forte visibilite.")}",
      "Mission: #{truncate_sentence(mission.search_constraints, fallback: "pilotage operationnel et accompagnement de la transformation.")}",
      "Entreprise: #{company_differentiator(mission)}"
    ]
  end

  def favorite_mission_ids
    session[:favorite_library_mission_ids] ||= []
    session[:favorite_library_mission_ids].map(&:to_i)
  end

  def build_client_insights(client_ids)
    return {} if client_ids.blank?

    placements = Placement
      .joins(mission: :client_contact)
      .where(client_contacts: { client_id: client_ids })
      .where(hired_at: 3.years.ago.to_date..Date.current)
      .includes(:mission)

    grouped = placements.group_by { |placement| placement.mission.client_contact.client_id }
    insights = {}

    client_ids.each do |client_id|
      rows = grouped[client_id] || []
      known = rows.any?
      durations = rows.filter_map do |placement|
        opened = placement.mission.opened_at
        hired = placement.hired_at
        next if opened.blank? || hired.blank?

        (hired - opened).to_i
      end
      avg_days = durations.any? ? (durations.sum / durations.size.to_f).round : nil

      reactivity = score_reactivity(avg_days)
      process_length = score_process(avg_days)
      geo_interest = score_geo_interest(rows)
      guarantees = score_guarantees(rows)
      stars = [ ((reactivity + process_length + geo_interest + guarantees) / 4.0).round, 1 ].max

      insights[client_id] = {
        known: known,
        stars: stars,
        reactivity: reactivity,
        process_length: process_length,
        geo_interest: geo_interest,
        guarantees: guarantees,
        avg_days: avg_days
      }
    end

    insights
  end

  def score_reactivity(avg_days)
    return 2 if avg_days.blank?
    return 5 if avg_days <= 20
    return 4 if avg_days <= 35
    return 3 if avg_days <= 50
    return 2 if avg_days <= 70

    1
  end

  def score_process(avg_days)
    return 2 if avg_days.blank?
    return 5 if avg_days <= 30
    return 4 if avg_days <= 45
    return 3 if avg_days <= 60
    return 2 if avg_days <= 90

    1
  end

  def score_geo_interest(rows)
    region_names = rows.map { |placement| placement.mission.region&.name.to_s }
    return 3 if region_names.empty?

    preferred_regions = [ "Hauts-de-France", "Ile-de-France", "Belgique" ]
    preferred_count = region_names.count { |name| preferred_regions.include?(name) }
    ratio = preferred_count.to_f / region_names.size
    return 5 if ratio >= 0.8
    return 4 if ratio >= 0.6
    return 3 if ratio >= 0.4
    return 2 if ratio >= 0.2

    1
  end

  def score_guarantees(rows)
    return 2 if rows.empty?

    trusted = rows.count { |placement| placement.status.in?(%w[paid pending_guarantee invoiced]) }
    ratio = trusted.to_f / rows.size
    return 5 if ratio >= 0.9
    return 4 if ratio >= 0.7
    return 3 if ratio >= 0.5
    return 2 if ratio >= 0.3

    1
  end

  def default_client_insight
    {
      known: false,
      stars: 2,
      reactivity: 2,
      process_length: 2,
      geo_interest: 3,
      guarantees: 2,
      avg_days: nil
    }
  end

  def format_amount(value)
    value.to_i.to_s.reverse.scan(/\d{1,3}/).join(" ").reverse
  end

  def mission_origin_badge(mission)
    case mission.origin_type.to_s
    when "rivyr"
      { label: "Mission RIVYR", style: "badge-primary" }
    when "freelancer"
      { label: "Apport freelance", style: "badge-secondary" }
    when "partner"
      { label: "Multi-diffusion client", style: "badge-accent" }
    else
      { label: "Partage label", style: "badge-info" }
    end
  end

  def mission_target_salary_average(mission)
    values = mission.compensation_summary.to_s.scan(/\d[\d\s]*/).map { |value| value.gsub(/\s/, "").to_i }.select(&:positive?)
    return 0 if values.empty?
    return values.first if values.one?

    ((values.first + values[1]) / 2.0).round
  end

  def mission_contract_fee_rate(mission)
    explicit = mission.compensation_summary.to_s[/(\d{1,2})\s*%/, 1].to_f
    explicit = mission.search_constraints.to_s[/(\d{1,2})\s*%/, 1].to_f if explicit.zero?
    return (explicit / 100.0) if explicit.positive?

    case mission.mission_type.to_s
    when "retained" then 0.22
    when "exclusive" then 0.20
    when "contingency" then 0.18
    else 0.20
    end
  end

  def mission_freelance_share_rate
    profile = current_user&.freelancer_profile
    return 0.40 if profile.blank?

    return 0.45 if profile.rivyr_score_current.to_i >= 90
    return 0.40 if profile.operational_status.to_s == "active"
    return 0.35 if profile.operational_status.to_s == "onboarded"

    0.30
  end

  def truncate_sentence(text, fallback:)
    value = text.to_s.strip
    value = fallback if value.blank?
    value = value.gsub(/\s+/, " ")
    value = value.first(115) + "..." if value.length > 115
    value
  end

  def company_differentiator(mission)
    client = mission.client_contact.client
    sector = client.sector.presence || "activite multisectorielle"
    size = mission_company_segment(mission)
    "#{size} du secteur #{sector}, environnement exigeant et evolutif."
  end
end
