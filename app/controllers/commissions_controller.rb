class CommissionsController < ApplicationController
  before_action :set_commission, only: [ :show, :edit, :update, :destroy ]
  before_action :set_placements, only: [ :new, :create, :edit, :update ]

  def index
    authorize Commission
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = policy_scope(Commission).includes(placement: [ :mission, :candidate ]).order(created_at: :desc).search(@q).with_status(@status)
    @commissions = paginate(scope)
  end

  def show
    authorize @commission
  end

  def new
    @commission = Commission.new(placement_id: params[:placement_id])
    authorize @commission
  end

  def create
    @commission = Commission.new(commission_params)
    authorize @commission

    if @commission.save
      redirect_to @commission, notice: "Commission creee avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @commission
  end

  def update
    authorize @commission

    if @commission.update(commission_params)
      redirect_to @commission, notice: "Commission mise a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @commission

    if @commission.destroy
      redirect_to commissions_path, status: :see_other, notice: "Commission supprimee avec succes."
    else
      redirect_to @commission, alert: "Impossible de supprimer cette commission."
    end
  end

  private

  def set_commission
    @commission = Commission.includes(placement: [ :mission, :candidate ]).find(params[:id])
  end

  def set_placements
    @placements = policy_scope(Placement).includes(:mission, :candidate).order(:id)
  end

  def commission_params
    params.require(:commission).permit(
      :placement_id,
      :commission_rule,
      :status,
      :gross_amount_cents,
      :rivyr_share_cents,
      :freelancer_share_cents,
      :client_payment_required,
      :eligible_for_invoicing_at
    )
  end
end
