class PaymentsController < ApplicationController
  before_action :set_payment, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize Payment
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = policy_scope(Payment).includes(:invoice, :commission).order(created_at: :desc).search(@q).with_status(@status)
    @payments = paginate(scope)
  end

  def show
    authorize @payment
  end

  def new
    @payment = Payment.new(
      invoice_id: params[:invoice_id],
      commission_id: params[:commission_id]
    )
    authorize @payment
  end

  def create
    @payment = Payment.new(payment_params)
    authorize @payment

    if @payment.save
      redirect_to @payment, notice: "Paiement créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @payment
  end

  def update
    authorize @payment

    if @payment.update(payment_params)
      redirect_to @payment, notice: "Paiement mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @payment

    if @payment.destroy
      redirect_to payments_path, status: :see_other, notice: "Paiement supprimé avec succès."
    else
      redirect_to @payment, alert: "Impossible de supprimer ce paiement."
    end
  end

  private

  def set_payment
    @payment = Payment.includes(:invoice, :commission).find(params[:id])
  end

  def set_form_collections
    @invoices = policy_scope(Invoice).order(:number)
    @commissions = policy_scope(Commission).order(:id)
  end

  def payment_params
    params.require(:payment).permit(
      :commission_id,
      :invoice_id,
      :status,
      :amount_cents,
      :paid_at,
      :payment_type,
      :reference
    )
  end
end
