class PaymentsController < ApplicationController
  before_action :set_payment, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    scope = Payment.includes(:invoice, :commission).order(created_at: :desc).search(@q).with_status(@status)
    @payments = paginate(scope)
  end

  def show
  end

  def new
    @payment = Payment.new(
      invoice_id: params[:invoice_id],
      commission_id: params[:commission_id]
    )
  end

  def create
    @payment = Payment.new(payment_params)

    if @payment.save
      redirect_to @payment, notice: "Paiement cree avec succes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @payment.update(payment_params)
      redirect_to @payment, notice: "Paiement mis a jour avec succes."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @payment.destroy
      redirect_to payments_path, status: :see_other, notice: "Paiement supprime avec succes."
    else
      redirect_to @payment, alert: "Impossible de supprimer ce paiement."
    end
  end

  private

  def set_payment
    @payment = Payment.includes(:invoice, :commission).find(params[:id])
  end

  def set_form_collections
    @invoices = Invoice.order(:number)
    @commissions = Commission.order(:id)
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
