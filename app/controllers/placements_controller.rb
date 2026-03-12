class PlacementsController < ApplicationController
  before_action :set_placement, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize Placement
    @q = params[:q].to_s.strip
    @status = params[:status].to_s.strip
    @scope = params[:scope].to_s.strip
    scope = policy_scope(Placement).includes(:mission, :candidate).order(created_at: :desc).search(@q).with_status(@status)

    if current_user.role_freelance? && @scope == "closed_missions"
      scope = scope.joins(:mission).where(missions: { status: "closed" })
    end

    @placements = paginate(scope)
  end

  def show
    authorize @placement

    @mission = @placement.mission
    @candidate = @placement.candidate
    @client_invoice = @placement.client_invoice
    @freelancer_invoice = @placement.freelancer_invoice
    @commission = @placement.commission
    @latest_payout_request = @freelancer_invoice&.payout_requests&.order(requested_at: :desc)&.first
    @invoice_notes = @client_invoice&.invoice_notes&.order(created_at: :desc)&.limit(8) || []
    @stage_states = build_stage_states
    @stage_index = @stage_states.rindex { |step| step[:done] } || 0
    @current_stage = @stage_states.find { |step| !step[:done] } || @stage_states.last
    @stage_actions = build_stage_actions(@current_stage[:key])
    @estimated_client_payment_date = estimate_client_payment_date
    @timeline_events = build_timeline_events
    @validation_checks = build_validation_checks
    @mission_stats = build_mission_stats
    @rivyr_followups = build_rivyr_followups
  end

  def new
    @placement = Placement.new
    authorize @placement
  end

  def create
    @placement = Placement.new(placement_params)
    authorize @placement

    if @placement.save
      redirect_to @placement, notice: "Placement créé avec succès."
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
      redirect_to @placement, notice: "Placement mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @placement

    if @placement.destroy
      redirect_to placements_path, status: :see_other, notice: "Placement supprimé avec succès."
    else
      redirect_to @placement, alert: "Impossible de supprimer ce placement."
    end
  end

  private

  def set_placement
    @placement = Placement.includes(
      :candidate,
      :commission,
      mission: { client_contact: :client },
      client_invoice: :invoice_notes,
      freelancer_invoice: :payout_requests
    ).find(params[:id])
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

  def estimate_client_payment_date
    return @client_invoice.paid_date if @client_invoice&.status_paid?
    return if @client_invoice.blank?

    @client_invoice.issue_date.present? ? (@client_invoice.issue_date + 15.days) : nil
  end

  def build_timeline_events
    events = []

    if @mission.contract_signed && @mission.opened_at.present?
      events << { date: @mission.opened_at, label: "Contrat signé", tone: "success" }
    end

    if @client_invoice.present?
      events << { date: @client_invoice.issue_date, label: "Facture client envoyée", tone: "warning" } if @client_invoice.issue_date.present?
      events << { date: @client_invoice.paid_date, label: "Paiement client confirmé", tone: "success" } if @client_invoice.paid_date.present?
    end

    @invoice_notes.each do |note|
      tone = note.action_required && note.resolved_at.blank? ? "action" : "info"
      events << { date: note.created_at.to_date, label: note.body, tone: tone }
    end

    if @latest_payout_request.present?
      tone = @latest_payout_request.status_paid? ? "success" : "info"
      events << {
        date: @latest_payout_request.requested_at.to_date,
        label: "Demande de virement #{@latest_payout_request.status} (#{@latest_payout_request.billing_number})",
        tone: tone
      }
    end

    events.compact.sort_by { |event| event[:date] }.reverse
  end

  def build_validation_checks
    [
      {
        label: "Contrat client signe",
        ok: @mission.contract_signed,
        detail: @mission.opened_at.present? ? "Signé le #{I18n.l(@mission.opened_at)}" : "Date non renseignée"
      },
      {
        label: "Promesse d'embauche",
        ok: @placement.hired_at.present?,
        detail: @placement.hired_at.present? ? "Démarrage le #{I18n.l(@placement.hired_at)}" : "À renseigner"
      },
      {
        label: "Candidat accepté",
        ok: @candidate.status == "placed" || @placement.hired_at.present?,
        detail: "Statut candidat: #{@candidate.status}"
      },
      {
        label: "Facture client créée",
        ok: @client_invoice.present?,
        detail: @client_invoice.present? ? @client_invoice.number : "Non créée"
      },
      {
        label: "Paiement client reçu",
        ok: @client_invoice&.status_paid?,
        detail: @client_invoice&.paid_date.present? ? "Payé le #{I18n.l(@client_invoice.paid_date)}" : "En attente"
      },
      {
        label: "Facture freelance émise",
        ok: @freelancer_invoice.present?,
        detail: @freelancer_invoice.present? ? @freelancer_invoice.number : "Non émise"
      }
    ]
  end

  def build_mission_stats
    mission_seed = @mission.reference.to_s.hash.abs
    sourced_candidates = 10 + (mission_seed % 8)
    applied_candidates = [ (sourced_candidates * 0.65).round, 1 ].max
    presented_candidates = [ (applied_candidates * 0.35).round, 1 ].max
    interviewed_candidates = [ (presented_candidates * 0.6).round, 1 ].max

    started_at = @mission.started_at || @mission.opened_at
    ended_at = @mission.closed_at || Date.current
    mission_duration_days = started_at.present? ? (ended_at - started_at).to_i : nil

    {
      duration_days: mission_duration_days,
      sourced_candidates: sourced_candidates,
      applied_candidates: applied_candidates,
      presented_candidates: presented_candidates,
      interviewed_candidates: interviewed_candidates
    }
  end

  def build_rivyr_followups
    followups = []

    if @client_invoice&.issue_date.present?
      followups << {
        occurred_at: @client_invoice.issue_date.to_time.change(hour: 10, min: 0),
        title: "Facture client envoyée",
        detail: "Facture #{@client_invoice.number} envoyée au contact client.",
        tone: "success"
      }
    end

    @invoice_notes.each do |note|
      followups << {
        occurred_at: note.created_at,
        title: note.action_required ? "Action demandée" : "Suivi Rivyr",
        detail: note.body,
        tone: note.action_required && note.resolved_at.blank? ? "action" : "info"
      }
    end

    if @latest_payout_request.present?
      followups << {
        occurred_at: @latest_payout_request.requested_at,
        title: "Demande de virement #{@latest_payout_request.status}",
        detail: "Référence : #{@latest_payout_request.billing_number}",
        tone: @latest_payout_request.status_paid? ? "success" : "info"
      }
    end

    followups.sort_by { |item| item[:occurred_at] }.reverse
  end

  def build_stage_states
    payout_pending_or_approved = @latest_payout_request&.status.in?(%w[pending approved])
    payout_paid = @latest_payout_request&.status_paid?
    wallet_available = @client_invoice&.status_paid? && @freelancer_invoice.present? && !payout_pending_or_approved && !payout_paid

    stages = [
      { key: :placement_realized, label: "Placement réalisé", done: @placement.hired_at.present? },
      { key: :documents_transmitted, label: "Documents transmis", done: @candidate.status.in?(%w[presented interviewing placed]) },
      { key: :documents_validated, label: "Documents validés", done: @mission.contract_signed? },
      { key: :client_invoice_created, label: "Création facture client", done: @client_invoice.present? },
      { key: :client_invoice_validated, label: "Facture validée", done: @client_invoice.present? && @client_invoice.issue_date.present? },
      { key: :client_invoice_sent, label: "Facture envoyée", done: @client_invoice&.status.in?(%w[issued paid]) },
      { key: :client_payment_started, label: "Paiement client", done: @client_invoice&.status.in?(%w[issued paid]) },
      { key: :client_payment_received, label: "Paiement client reçu", done: @client_invoice&.status_paid? },
      { key: :freelancer_invoice_created, label: "Création facture freelance", done: @freelancer_invoice.present? },
      { key: :freelancer_invoice_validated, label: "Validation facture freelance", done: @freelancer_invoice.present? },
      { key: :in_payment, label: "En paiement", done: payout_pending_or_approved || payout_paid },
      { key: :wallet_available, label: "Virement wallet disponible", done: wallet_available || payout_pending_or_approved || payout_paid },
      { key: :paid, label: "Payé", done: payout_paid }
    ]

    first_missing_index = stages.index { |stage| !stage[:done] }
    return stages if first_missing_index.nil?

    stages.each_with_index do |stage, index|
      stage[:active] = index == first_missing_index
    end
    stages
  end

  def build_stage_actions(stage_key)
    case stage_key
    when :documents_transmitted
      [
        { label: "Transmettre documents", path: edit_placement_path(@placement), kind: :link, style: "btn-primary" },
        { label: "Confirmer acceptation candidat", path: candidate_path(@candidate), kind: :link, style: "btn-outline" },
        { label: "Confirmer acceptation client", path: mission_path(@mission), kind: :link, style: "btn-outline" }
      ]
    when :documents_validated
      [
        { label: "Valider les documents", path: mission_path(@mission), kind: :link, style: "btn-primary" },
        { label: "Voir contrat client", path: mission_path(@mission), kind: :link, style: "btn-outline" }
      ]
    when :client_invoice_created
      [
        { label: "Créer facture client", path: create_client_invoice_freelance_finance_path, kind: :post, style: "btn-primary", params: { placement_id: @placement.id } }
      ]
    when :client_payment_received
      if @freelancer_invoice.blank?
        [
          { label: "Créer facture freelance", path: create_freelancer_invoice_freelance_finance_path, kind: :post, style: "btn-secondary", params: { placement_id: @placement.id } }
        ]
      else
        []
      end
    when :wallet_available
      if @freelancer_invoice.present?
        [
          {
            label: "Demander le paiement",
            path: create_payout_request_freelance_finance_path,
            kind: :post,
            style: "btn-accent",
            params: {
              invoice_id: @freelancer_invoice.id,
              amount_cents: @freelancer_invoice.amount_cents,
              billing_number: @freelancer_invoice.number
            }
          }
        ]
      else
        []
      end
    else
      [
        { label: "Voir détails mission", path: mission_path(@mission), kind: :link, style: "btn-outline" }
      ]
    end
  end
end
