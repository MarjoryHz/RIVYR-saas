class PlacementsController < ApplicationController
  before_action :set_placement, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize Placement
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = policy_scope(Placement).includes(:mission, :candidate).order(created_at: :desc).search(@q).with_status(@status)
    @placements = paginate(scope)
  end

  def show
    authorize @placement
  end

  def new
    @placement = Placement.new
    authorize @placement
  end

  def create
    @placement = Placement.new(placement_params)
    authorize @placement

    if @placement.save
      redirect_to @placement, notice: "Placement cree avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @placement
  end

  def update
    authorize @placement

    if @placement.update(placement_params)
      redirect_to @placement, notice: "Placement mis a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @placement

    if @placement.destroy
      redirect_to placements_path, status: :see_other, notice: "Placement supprime avec succes."
    else
      redirect_to @placement, alert: "Impossible de supprimer ce placement."
    end
  end

  private

  def set_placement
    @placement = Placement.includes(:mission, :candidate).find(params[:id])
  end

  def set_form_collections
    @missions = policy_scope(Mission).order(:reference)
    @candidates = policy_scope(Candidate).order(:last_name, :first_name)
  end

  def placement_params
    params.require(:placement).permit(
      :mission_id,
      :candidate_id,
      :status,
      :hired_at,
      :annual_salary_cents,
      :placement_fee_cents,
      :notes
    )
  end
end
