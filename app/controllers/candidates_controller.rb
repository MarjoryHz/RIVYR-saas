class CandidatesController < ApplicationController
  before_action :set_candidate, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Candidate
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = policy_scope(Candidate).order(:last_name, :first_name).search(@q).with_status(@status)
    @candidates = paginate(scope)
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
      redirect_to @candidate, notice: "Candidat cree avec succes."
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
      redirect_to @candidate, notice: "Candidat mis a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @candidate

    if @candidate.destroy
      redirect_to candidates_path, status: :see_other, notice: "Candidat supprime avec succes."
    else
      redirect_to @candidate, alert: "Impossible de supprimer ce candidat."
    end
  end

  private

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
