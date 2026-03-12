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
      redirect_to @invoice, notice: "Facture créée avec succès."
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
      redirect_to @invoice, notice: "Facture mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invoice

    if @invoice.destroy
      redirect_to invoices_path, status: :see_other, notice: "Facture supprimée avec succès."
    else
      redirect_to @invoice, alert: "Impossible de supprimer cette facture."
    end
  end

  def create_note
    @invoice = Invoice.find(params[:id])
    authorize @invoice

    note = @invoice.invoice_notes.new(invoice_note_params.merge(user: current_user))
    if note.save
      redirect_to @invoice, notice: "Note de suivi ajoutée."
    else
      redirect_to @invoice, alert: note.errors.full_messages.to_sentence
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

  def invoice_note_params
    params.require(:invoice_note).permit(:body, :action_required, :note_type)
  end
end
