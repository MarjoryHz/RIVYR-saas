class CandidatesController < ApplicationController
  before_action :set_candidate, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Candidate
    @q                   = params[:q].to_s.strip
    @availability        = params[:availability].to_s.strip
    @location            = params[:location].to_s.strip
    @contract_type       = params[:contract_type].to_s.strip
    @salary_range        = params[:salary_range].to_s.strip
    @language_code       = params[:language_code].to_s.strip
    @language_level      = params[:language_level].to_s.strip
    @job_title           = params[:job_title].to_s.strip
    @selected_skills     = Array(params[:skills]).map(&:strip).reject(&:blank?)
    @only_favorites      = params[:only_favorites] == "1"
    @selected_mission_id = params[:selected_mission_id].presence&.to_i

    # Missions actives attribuées au freelance connecté (ou toutes si admin)
    active_statuses = %w[open in_progress]
    @open_missions = if current_user.freelancer_profile
      current_user.freelancer_profile.missions
        .includes(client_contact: :client)
        .where(status: active_statuses)
        .order(:title)
    else
      policy_scope(Mission)
        .includes(client_contact: :client)
        .where(status: active_statuses)
        .order(:title)
    end
    @selected_mission = @selected_mission_id ? @open_missions.find_by(id: @selected_mission_id) : nil

    base_scope = policy_scope(Candidate)

    # Stats
    @total_count     = base_scope.count
    @qualified_count = base_scope.where(status: %w[qualified presented interviewing placed]).count
    @available_count = base_scope.where(availability: %w[immediate one_month]).count

    # Filter dropdown options
    @location_options       = base_scope.where.not(location: [nil, ""]).distinct.pluck(:location).sort
    @job_title_options      = WorkExperience.where.not(title: [nil, ""]).distinct.order(:title).pluck(:title)
    @job_title_skills_map   = WorkExperience
      .where.not(title: nil)
      .pluck(:title, :skills)
      .group_by(&:first)
      .transform_values { |rows| rows.flat_map(&:last).compact.flatten.uniq.sort }

    scope = base_scope
      .includes(:work_experiences, :educations, placements: { mission: { freelancer_profile: :user } })
      .order(:last_name, :first_name)
      .search(@q)

    scope = scope.where(availability: @availability)                                        if @availability.present?
    scope = scope.where(location: @location)                                                if @location.present?
    scope = scope.where("? = ANY(contract_types)", @contract_type)                          if @contract_type.present?
    scope = scope.where(salary_range: @salary_range)                                        if @salary_range.present?
    scope = scope.joins(:work_experiences).where(work_experiences: { title: @job_title }).distinct if @job_title.present?
    scope = scope.where("skills && ARRAY[?]::varchar[]", @selected_skills)                  if @selected_skills.any?
    if @language_code.present?
      json = @language_level.present? ? [{ code: @language_code, level: @language_level }].to_json : [{ code: @language_code }].to_json
      scope = scope.where("languages @> ?::jsonb", json)
    end
    if @only_favorites
      fav_scope = current_user.favorite_candidates.where(mission_id: @selected_mission_id)
      scope = scope.where(id: fav_scope.select(:candidate_id))
    end

    @candidates = paginate(scope, per_page: 21)

    # Compte des candidats en favoris pour la mission sélectionnée (ou global)
    @mission_fav_counts = @open_missions.index_with do |m|
      current_user.favorite_candidates.where(mission_id: m.id).count
    end
    @global_fav_count = current_user.favorite_candidates.where(mission_id: nil).count

    @favorite_candidate_ids = current_user.favorite_candidates
      .where(mission_id: @selected_mission_id)
      .pluck(:candidate_id).to_set

    # Map complète des favoris par mission pour le SwipeSelector (mission_id => [candidate_ids])
    all_favs = current_user.favorite_candidates.pluck(:mission_id, :candidate_id)
    @favorites_by_mission = all_favs.group_by(&:first).transform_values { |rows| rows.map(&:last) }

    @candidate_rows = @candidates.map { |candidate| build_candidate_row(candidate) }
  end

  def toggle_favorite
    @candidate = Candidate.find(params[:id])
    authorize @candidate, :show?

    @selected_mission_id = params[:mission_id].presence&.to_i
    favorite = current_user.favorite_candidates.find_by(candidate_id: @candidate.id, mission_id: @selected_mission_id)
    if favorite.present?
      favorite.destroy!
      @is_favorite = false
    else
      current_user.favorite_candidates.create!(candidate: @candidate, mission_id: @selected_mission_id)
      @is_favorite = true
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to params[:return_to].presence || (request.path.start_with?("/dashboard") ? dashboard_candidates_path : candidates_path) }
    end
  end

  def show
    authorize @candidate
  end

  def new
    @candidate = Candidate.new
    authorize @candidate
  end

  def create
    @candidate = Candidate.new(candidate_params)
    authorize @candidate

    if @candidate.save
      redirect_to @candidate, notice: "Candidat créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @candidate
  end

  def update
    authorize @candidate

    if @candidate.update(candidate_params)
      redirect_to @candidate, notice: "Candidat mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @candidate

    if @candidate.destroy
      redirect_to candidates_path, status: :see_other, notice: "Candidat supprimé avec succès."
    else
      redirect_to @candidate, alert: "Impossible de supprimer ce candidat."
    end
  end

  private

  def build_candidate_row(candidate)
    latest_placement  = candidate.placements.max_by(&:created_at)
    latest_mission    = latest_placement&.mission
    latest_freelancer = latest_mission&.freelancer_profile&.user
    current_exp       = candidate.work_experiences.find(&:current?) || candidate.work_experiences.first

    {
      candidate:        candidate,
      full_name:        [ candidate.first_name, candidate.last_name ].compact.join(" "),
      initials:         [ candidate.first_name, candidate.last_name ].filter_map { |part| part.to_s.first }.join.upcase.first(2),
      avatar_path:      candidate_avatar_path(candidate),
      certified:        !candidate.status_new?,
      seen:             candidate.placements.any?,
      freelance_name:   latest_freelancer.present? ? [ latest_freelancer.first_name, latest_freelancer.last_name ].compact.join(" ") : nil,
      last_position:    current_exp&.title.presence || candidate.job_titles&.last.presence || "Profil en cours de qualification",
      current_company:  current_exp&.company,
      top_skills:       top_candidate_skills(candidate),
      search_status:    candidate_search_status(candidate),
      status_badge:     candidate_status_badge(candidate)
    }
  end

  def top_candidate_skills(candidate)
    last_skills = candidate.work_experiences.first&.skills.to_a.compact
    return last_skills.first(4) if last_skills.any?

    candidate.work_experiences.flat_map(&:skills).compact
      .tally.sort_by { |_, count| -count }.first(4).map(&:first)
  end

  def candidate_search_status(candidate)
    case candidate.status
    when "interviewing", "presented"
      { label: "Recherche active", tone: "emerald" }
    when "placed"
      { label: "Pas en recherche", tone: "slate" }
    else
      { label: "Recherche passive", tone: "amber" }
    end
  end

  def candidate_status_badge(candidate)
    case candidate.status
    when "qualified"
      { label: "Qualifie Rivyr", tone: "pink" }
    when "presented", "interviewing"
      { label: "Deja vu", tone: "sky" }
    when "placed"
      { label: "Place", tone: "emerald" }
    else
      { label: "A qualifier", tone: "slate" }
    end
  end

  def candidate_avatar_path(candidate)
    avatar_index = (candidate.id || candidate.email.to_s.sum) % 10 + 1
    "avatars/avatar-#{format('%02d', avatar_index)}.png"
  end

  def set_candidate
    @candidate = Candidate.find(params[:id])
  end

  def candidate_params
    params.require(:candidate).permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :linkedin_url,
      :website_url,
      :location,
      :status,
      :notes,
      :source,
      job_titles: [],
      skills: []
    )
  end
end
