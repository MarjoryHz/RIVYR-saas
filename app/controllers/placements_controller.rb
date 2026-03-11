class PlacementsController < ApplicationController
  before_action :set_placement, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = Placement.includes(:mission, :candidate).order(created_at: :desc).search(@q).with_status(@status)
    @placements = paginate(scope)
  end

  def show
  end

  def new
    @placement = Placement.new
  end

  def create
    @placement = Placement.new(placement_params)

    if @placement.save
      redirect_to @placement, notice: "Placement cree avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @placement.update(placement_params)
      redirect_to @placement, notice: "Placement mis a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
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
    @missions = Mission.order(:reference)
    @candidates = Candidate.order(:last_name, :first_name)
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
