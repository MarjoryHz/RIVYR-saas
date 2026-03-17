class PlacementsController < ApplicationController
  before_action :set_placement, only: [ :show, :edit, :update, :destroy, :validate_compliance, :refuse_compliance ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize Placement
    @q = params[:q].to_s.strip
    @tab = params[:tab].presence_in(%w[in_progress validated refused]) || "in_progress"
    @company_filter = params[:company].to_s.strip
    @region_filter = params[:region].to_s.strip
    @amount_filter = params[:amount].to_s.strip
    base_scope = policy_scope(Placement)
      .includes(:candidate, :commission, :freelancer_profile, mission: [ :region, { client_contact: :client } ])
      .order(updated_at: :desc, created_at: :desc)
      .search(@q)

    @placement_counts = {
      "in_progress" => base_scope.with_workflow_status("in_progress").count,
      "validated" => base_scope.with_workflow_status("validated").count,
      "refused" => base_scope.with_workflow_status("refused").count
    }

    placement_rows = base_scope.with_workflow_status(@tab).map { |placement| build_placement_row(placement) }
    @company_options = placement_rows.map { |row| row[:company_name] }.compact.uniq.sort
    @region_options = placement_rows.map { |row| row[:region_name] }.compact.uniq.sort
    @placement_rows = filter_placement_rows(placement_rows)
    @placement_metrics = build_placement_metrics(base_scope)
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

  def validate_compliance
    authorize @placement, :validate_compliance?
    return redirect_to placement_path(@placement), alert: "Les informations du placement sont incomplètes." unless @placement.ready_for_admin_review?

    Placement.transaction do
      @placement.sync_commission!
      @placement.update!(
        workflow_status: "validated",
        admin_reviewed_at: Time.current,
        admin_reviewed_by_id: current_user.id,
        admin_review_note: params[:admin_review_note].presence
      )
    end

    redirect_to placement_path(@placement), notice: "Le placement a été validé."
  end

  def refuse_compliance
    authorize @placement, :refuse_compliance?

    @placement.update!(
      workflow_status: "refused",
      admin_reviewed_at: Time.current,
      admin_reviewed_by_id: current_user.id,
      admin_review_note: params[:admin_review_note].presence
    )

    redirect_to placement_path(@placement), notice: "Le placement a été refusé."
  end

  private

  def set_placement
    @placement = Placement.includes(
      :candidate,
      :commission,
      :freelancer_profile,
      mission: { client_contact: :client, freelancer_profile: :user },
      client_invoice: :invoice_notes,
      freelancer_invoice: :payout_requests
    ).find(params[:id])
  end

  def set_form_collections
    @missions = policy_scope(Mission).order(:reference)
    @candidates = policy_scope(Candidate).order(:last_name, :first_name)
  end

  def placement_params
    permitted = [
      :mission_id,
      :candidate_id,
      :status,
      :hired_at,
      :annual_salary_cents,
      :placement_fee_cents,
      :notes,
      :package_summary,
      :client_offer_compliant,
      :candidate_accepted
    ]
    permitted.concat([ :workflow_status, :admin_review_note ]) if current_user&.role_admin?

    params.require(:placement).permit(*permitted)
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
        label: "Rémunération renseignée",
        ok: @placement.annual_salary_cents.to_i.positive?,
        detail: @placement.annual_salary_cents.to_i.positive? ? helpers.number_to_currency(@placement.annual_salary_cents / 100.0, unit: "€", precision: 0) : "À renseigner"
      },
      {
        label: "Package validé",
        ok: @placement.package_summary.present?,
        detail: @placement.package_summary.presence || "À renseigner"
      },
      {
        label: "Conformité à l'offre client",
        ok: @placement.client_offer_compliant == true,
        detail: @placement.client_offer_compliant.nil? ? "À vérifier" : (@placement.client_offer_compliant? ? "Conforme" : "Non conforme")
      },
      {
        label: "Acceptation du candidat",
        ok: @placement.candidate_accepted == true,
        detail: @placement.candidate_accepted.nil? ? "À confirmer" : (@placement.candidate_accepted? ? "Accepté" : "Refusé")
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

  def load_closed_missions_dashboard(scope)
    placements = scope.to_a
    all_rows = placements.map do |placement|
      mission = placement.mission
      client = mission.client_contact.client
      started_on = mission.started_at || mission.opened_at || mission.created_at.to_date
      ended_on = mission.closed_at || placement.hired_at || Date.current

      {
        placement: placement,
        mission: mission,
        company_name: client.brand_name.presence || client.legal_name,
        company_logo: client.logo,
        client_contact_name: [ mission.client_contact.first_name, mission.client_contact.last_name ].compact.join(" "),
        region_name: mission.region&.name,
        potential_cents: placement.commission&.freelancer_share_cents.to_i,
        duration_days: [ (ended_on - started_on).to_i, 0 ].max,
        candidate_name: [ placement.candidate.first_name, placement.candidate.last_name ].compact.join(" "),
        closed_steps: [
          { label: "Entretien client", done: true },
          { label: "Recruté", done: true },
          { label: "Validé", done: true }
        ]
      }
    end

    @company_options = all_rows.map { |row| row[:company_name] }.compact.uniq.sort
    @region_options = all_rows.map { |row| row[:region_name] }.compact.uniq.sort
    @closed_missions_count = all_rows.size
    @closed_placement_rows = filter_closed_mission_rows(all_rows)
    @closed_total_cents = @closed_placement_rows.sum { |row| row[:potential_cents] }
    @closed_average_days = if @closed_placement_rows.any?
      (@closed_placement_rows.sum { |row| row[:duration_days] } / @closed_placement_rows.size.to_f).round
    else
      0
    end
    @closed_candidates_count = @closed_placement_rows.count { |row| row[:candidate_name].present? }
  end

  def filter_closed_mission_rows(rows)
    rows.select do |row|
      matches_company = @company_filter.blank? || row[:company_name] == @company_filter
      matches_region = @region_filter.blank? || row[:region_name] == @region_filter
      matches_amount = if @amount_filter.blank?
        true
      else
        amount_cents = row[:potential_cents]

        case @amount_filter
        when "lt_5000"
          amount_cents < 500_000
        when "between_5000_10000"
          amount_cents >= 500_000 && amount_cents <= 1_000_000
        when "gt_10000"
          amount_cents > 1_000_000
        else
          true
        end
      end

      matches_company && matches_region && matches_amount
    end
  end

  def build_placement_row(placement)
    mission = placement.mission
    client = mission.client_contact.client

    {
      placement: placement,
      mission_title: mission.title,
      mission_reference: mission.reference,
      company_name: client.brand_name.presence || client.legal_name,
      company_logo: client.logo,
      region_name: mission.region&.name,
      candidate_name: [ placement.candidate.first_name, placement.candidate.last_name ].compact.join(" "),
      candidate_status: placement.candidate.status,
      salary_cents: placement.annual_salary_cents.to_i,
      workflow_label: workflow_label_for(placement),
      workflow_badge_class: workflow_badge_class_for(placement),
      compliance_label: placement.client_offer_compliant.nil? ? "À vérifier" : (placement.client_offer_compliant? ? "Conforme à l'offre client" : "Écart à traiter"),
      package_summary: placement.package_summary.presence || "Package à confirmer",
      updated_at: placement.updated_at
    }
  end

  def filter_placement_rows(rows)
    rows.select do |row|
      matches_company = @company_filter.blank? || row[:company_name] == @company_filter
      matches_region = @region_filter.blank? || row[:region_name] == @region_filter
      matches_amount =
        case @amount_filter
        when "under_5000" then row[:salary_cents] < 500_000
        when "5000_10000" then row[:salary_cents] >= 500_000 && row[:salary_cents] <= 1_000_000
        when "10000_20000" then row[:salary_cents] > 1_000_000 && row[:salary_cents] <= 2_000_000
        when "over_20000" then row[:salary_cents] > 2_000_000
        else true
        end

      matches_company && matches_region && matches_amount
    end
  end

  def build_placement_metrics(scope)
    placements = scope.to_a

    {
      signatures_count: placements.count { |placement| placement.mission.contract_signed? },
      placements_count: placements.count(&:workflow_validated?),
      payments_count: placements.count { |placement| placement.client_invoice&.status_paid? }
    }
  end

  def workflow_label_for(placement)
    case placement.workflow_status
    when "validated" then "Validé"
    when "refused" then "Refusé"
    else "En cours"
    end
  end

  def workflow_badge_class_for(placement)
    case placement.workflow_status
    when "validated" then "border-[#d7e9dc] bg-[#edf8f0] text-[#2f6b3c]"
    when "refused" then "border-[#f1c9d3] bg-[#fff1f4] text-[#b14360]"
    else "border-[#f3dfc8] bg-[#fff3e8] text-[#ba6d2f]"
    end
  end
end
