class InvoicesController < ApplicationController
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy ]
  before_action :set_placements, only: [ :new, :create, :edit, :update ]

  def index
    authorize Invoice
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = policy_scope(Invoice).includes(placement: [ :mission, :candidate ]).order(created_at: :desc).search(@q).with_status(@status)
    @invoices = paginate(scope)
  end

  def show
    authorize @invoice
  end

  def new
    @invoice = Invoice.new(placement_id: params[:placement_id])
    authorize @invoice
  end

  def create
    @invoice = Invoice.new(invoice_params)
    authorize @invoice

    if @invoice.save
      redirect_to @invoice, notice: "Facture creee avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @invoice
  end

  def update
    authorize @invoice

    if @invoice.update(invoice_params)
      redirect_to @invoice, notice: "Facture mise a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invoice

    if @invoice.destroy
      redirect_to invoices_path, status: :see_other, notice: "Facture supprimee avec succes."
    else
      redirect_to @invoice, alert: "Impossible de supprimer cette facture."
    end
  end

  private

  def set_invoice
    @invoice = Invoice.includes(placement: [ :mission, :candidate ]).find(params[:id])
  end

  def set_placements
    @placements = policy_scope(Placement).includes(:mission, :candidate).order(:id)
  end

  def invoice_params
    params.require(:invoice).permit(
      :placement_id,
      :invoice_type,
      :number,
      :status,
      :issue_date,
      :paid_date,
      :amount_cents
    )
  end
end
