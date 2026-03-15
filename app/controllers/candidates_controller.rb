class CandidatesController < ApplicationController
  before_action :set_candidate, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Candidate
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = policy_scope(Candidate)
      .includes(placements: { mission: { freelancer_profile: :user } })
      .order(:last_name, :first_name)
      .search(@q)
      .with_status(@status)
    @candidates = paginate(scope)
    @candidate_rows = @candidates.map { |candidate| build_candidate_row(candidate) }
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
    latest_placement = candidate.placements.max_by(&:created_at)
    latest_mission = latest_placement&.mission
    latest_freelancer = latest_mission&.freelancer_profile&.user

    {
      candidate: candidate,
      full_name: [ candidate.first_name, candidate.last_name ].compact.join(" "),
      initials: [ candidate.first_name, candidate.last_name ].filter_map { |part| part.to_s.first }.join.upcase.first(2),
      avatar_path: candidate_avatar_path(candidate),
      certified: !candidate.status_new?,
      seen: candidate.placements.any?,
      freelance_name: latest_freelancer.present? ? [ latest_freelancer.first_name, latest_freelancer.last_name ].compact.join(" ") : nil,
      last_position: latest_mission&.title.presence || candidate.source.to_s.humanize.presence || "Profil en cours de qualification",
      search_status: candidate_search_status(candidate),
      status_badge: candidate_status_badge(candidate)
    }
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
      :status,
      :notes,
      :source
    )
  end
end
