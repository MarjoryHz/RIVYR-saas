class FreelanceFinancesController < ApplicationController
  before_action :set_placements_scope

  def show
    authorize :freelance_finance, :show?
    @freelancer_profile = current_user.freelancer_profile
    @tab = params[:tab].presence_in(%w[signatures placements payments]) || "signatures"
    @wallet_tab = params[:wallet_tab].presence_in(%w[available waiting potential]) || "available"
    @signature_status = params[:signature_status].presence_in(%w[transmitted client_signing client_changes_requested signed refused expired]).to_s
    @signature_archive_client = params[:signature_archive_client].to_s.strip
    @signature_archive_mission = params[:signature_archive_mission].to_s.strip
    @signature_archive_date = params[:signature_archive_date].to_s.strip
    @signature_changes_only = params[:signature_changes_only].to_s == "1"
    @placements_changes_only = params[:placements_changes_only].to_s == "1"
    @payment_status = params[:payment_status].to_s
    @payment_changes_only = params[:payment_changes_only].to_s == "1"
    @q = params[:q].to_s.strip
    @client_invoice_status = params[:client_invoice_status].to_s.strip
    @payout_status = params[:payout_status].to_s.strip
    @action_required = params[:action_required].to_s == "1"

    @missions = finance_missions_scope
    @placements = filtered_placements
    @available_wallet_cents = available_wallet_cents
    @waiting_client_payments_cents = waiting_client_payments_cents
    @potential_wallet_cents = potential_wallet_cents
    @finance_overview = finance_overview_data
    @wallet_bank_account_options = @freelancer_profile&.bank_accounts.to_a.map { |account| [ account[:label], account[:label] ] }
    @wallet_payout_invoice = own_freelancer_invoices.order(issue_date: :desc, created_at: :desc).max_by do |invoice|
      requestable_invoice_amount_cents(invoice)
    end
    @wallet_requestable_amount_cents =
      if @wallet_payout_invoice.present?
        [ requestable_invoice_amount_cents(@wallet_payout_invoice), @available_wallet_cents ].min
      else
        0
      end

    seen_tabs = finance_seen_tabs
    @finance_tabs = build_finance_tabs(seen_tabs)
    @active_finance_tab = @finance_tabs.find { |tab| tab[:key] == @tab } || @finance_tabs.first
    @active_finance_tab[:unseen_count] = 0 if @active_finance_tab.present?
    mark_finance_tab_seen!(@tab)
  end

  def create_client_invoice
    authorize :freelance_finance, :create_client_invoice?

    placement = @placements_scope.find(params[:placement_id])
    if placement.client_invoice.present?
      return redirect_to dashboard_freelance_finance_path, alert: "Une facture client existe déjà pour ce placement."
    end

    invoice = placement.invoices.new(
      invoice_type: "client",
      number: next_invoice_number("RIV-CLI"),
      status: "issued",
      issue_date: Date.current,
      amount_cents: placement.placement_fee_cents.to_i
    )

    if invoice.save
      redirect_to dashboard_freelance_finance_path, notice: "Facture client générée et transmise à Rivyr pour suivi."
    else
      redirect_to dashboard_freelance_finance_path, alert: invoice.errors.full_messages.to_sentence
    end
  end

  def create_freelancer_invoice
    authorize :freelance_finance, :create_freelancer_invoice?

    placement = @placements_scope.find(params[:placement_id])
    if placement.freelancer_invoice.present?
      return redirect_to dashboard_freelance_finance_path, alert: "Une facture freelance existe déjà pour ce placement."
    end

    unless placement.client_invoice&.status_paid?
      return redirect_to dashboard_freelance_finance_path, alert: "La facture client doit être encaissée par Rivyr avant facturation freelance."
    end

    commission_amount = placement.commission&.freelancer_share_cents.to_i
    if commission_amount <= 0
      return redirect_to dashboard_freelance_finance_path, alert: "Aucune commission freelance disponible pour ce placement."
    end

    invoice = placement.invoices.new(
      invoice_type: "freelancer",
      number: next_invoice_number("FRL"),
      status: "issued",
      issue_date: Date.current,
      amount_cents: commission_amount
    )

    if invoice.save
      redirect_to dashboard_freelance_finance_path, notice: "Facture freelance créée avec succès."
    else
      redirect_to dashboard_freelance_finance_path, alert: invoice.errors.full_messages.to_sentence
    end
  end

  def create_payout_request
    authorize :freelance_finance, :create_payout_request?

    invoice = own_freelancer_invoices.find(params[:invoice_id])
    amount_cents =
      if params[:amount_eur].present?
        (params[:amount_eur].to_f * 100).round
      else
        params[:amount_cents].to_i
      end
    amount_cents = invoice.amount_cents if amount_cents <= 0

    if amount_cents > available_wallet_cents
      flash[:payout_request_insufficient] = {
        requested_amount_cents: amount_cents,
        available_amount_cents: available_wallet_cents
      }
      return redirect_to dashboard_freelance_finance_path
    end

    if amount_cents > requestable_invoice_amount_cents(invoice)
      flash[:payout_request_insufficient] = {
        requested_amount_cents: amount_cents,
        available_amount_cents: [ requestable_invoice_amount_cents(invoice), available_wallet_cents ].min
      }
      return redirect_to dashboard_freelance_finance_path
    end

    payout_request = current_user.payout_requests.new(
      invoice: invoice,
      amount_cents: amount_cents,
      billing_number: params[:billing_number].presence || invoice.number,
      bank_account_label: params[:bank_account_label].presence,
      note: params[:note].presence,
      requested_at: Time.current
    )

    if payout_request.save
      flash[:payout_request_success] = {
        amount_cents: amount_cents,
        bank_account_label: payout_request.bank_account_label.presence || "Compte bancaire"
      }
      redirect_to dashboard_freelance_finance_path, notice: "Demande de virement envoyée à Rivyr."
    else
      redirect_to dashboard_freelance_finance_path, alert: payout_request.errors.full_messages.to_sentence
    end
  end

  private

  def filtered_placements
    scope = @placements_scope

    if @q.present?
      scope = scope.where("missions.reference ILIKE :q OR missions.title ILIKE :q", q: "%#{@q}%")
    end

    case @client_invoice_status
    when "none"
      scope = scope.where.missing(:client_invoice)
    when "issued", "paid", "canceled"
      scope = scope.joins(:client_invoice).where(invoices: { status: @client_invoice_status })
    end

    placements = scope.order(created_at: :desc).to_a
    placements = placements.select { |placement| placement.client_invoice&.invoice_notes&.any? { |note| note.action_required && note.resolved_at.blank? } } if @action_required

    case @payout_status
    when "none"
      placements = placements.select { |placement| placement.freelancer_invoice.blank? || placement.freelancer_invoice.payout_requests.none? }
    when "pending", "approved", "paid", "rejected"
      placements = placements.select do |placement|
        placement.freelancer_invoice&.payout_requests&.any? { |request| request.status == @payout_status }
      end
    end

    placements
  end

  def filtered_payout_requests
    scope = current_user.payout_requests.includes(:invoice).order(requested_at: :desc)
    return scope if @payout_status.blank? || @payout_status == "none"

    scope.where(status: @payout_status)
  end

  def set_placements_scope
    @placements_scope = Placement
      .includes(
        :commission,
        mission: { client_contact: :client },
        client_invoice: :invoice_notes,
        freelancer_invoice: :payout_requests
      )
      .joins(mission: :freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })
  end

  def finance_missions_scope
    @finance_missions_scope ||= Mission
      .includes(:placement, placement: :commission, client_contact: :client)
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id }, status: %w[open in_progress])
      .order(updated_at: :desc, created_at: :desc)
      .to_a
  end

  def all_signature_rows
    @all_signature_rows ||= (@missions + finance_archived_missions_scope).filter_map { |mission| signature_row_for(mission) }
  end

  def finance_archived_missions_scope
    @finance_archived_missions_scope ||= Mission
      .includes(:placement, placement: :commission, client_contact: :client)
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id }, status: "closed")
      .order(closed_at: :desc, updated_at: :desc, created_at: :desc)
      .to_a
  end

  def own_freelancer_invoices
    Invoice
      .joins(placement: { mission: :freelancer_profile })
      .where(freelancer_profiles: { user_id: current_user.id }, invoice_type: "freelancer")
  end

  def requestable_invoice_amount_cents(invoice)
    return 0 if invoice.blank?

    consumed_cents = current_user.payout_requests.where(invoice: invoice).where.not(status: "rejected").sum(:amount_cents)
    [ invoice.amount_cents.to_i - consumed_cents, 0 ].max
  end

  def activated_commissions_cents
    @activated_commissions_cents ||= @placements_scope.to_a.sum do |placement|
      next 0 unless placement.client_invoice&.status_paid?

      placement.commission&.freelancer_share_cents.to_i
    end
  end

  def paid_out_cents
    current_user.payout_requests.where(status: "paid").sum(:amount_cents)
  end

  def reserved_payout_cents
    current_user.payout_requests.where(status: [ "pending", "approved" ]).sum(:amount_cents)
  end

  def available_wallet_cents
    [ activated_commissions_cents - paid_out_cents - reserved_payout_cents, 0 ].max
  end

  def gross_kpis
    invoices = own_freelancer_invoices
    now = Date.current

    {
      ytd_cents: invoices.where(issue_date: now.beginning_of_year..now.end_of_year).sum(:amount_cents),
      last_3_months_cents: invoices.where(issue_date: (now - 3.months).beginning_of_month..now.end_of_month).sum(:amount_cents),
      last_6_months_cents: invoices.where(issue_date: (now - 6.months).beginning_of_month..now.end_of_month).sum(:amount_cents),
      monthly: monthly_gross_series(invoices)
    }
  end

  def waiting_client_payments_cents
    @placements.sum do |placement|
      invoice = placement.client_invoice
      next 0 if invoice.blank? || invoice.status_paid?

      invoice.amount_cents.to_i
    end
  end

  def potential_wallet_cents
    @missions.sum do |mission|
      mission.placement&.commission&.freelancer_share_cents.to_i.nonzero? || estimated_mission_commission_cents(mission)
    end
  end

  def build_finance_tabs(seen_tabs)
    [
      build_signatures_tab(seen_tabs),
      build_placements_tab(seen_tabs),
      build_payments_tab(seen_tabs)
    ]
  end

  def build_signatures_tab(seen_tabs)
    seen_at = finance_seen_at_for(seen_tabs, "signatures")
    all_active_signature_rows = @missions.filter_map { |mission| signature_row_for(mission) }
    all_archived_signature_rows = finance_archived_missions_scope.filter_map { |mission| signature_row_for(mission) }
    all_rows = all_active_signature_rows + all_archived_signature_rows
    signature_rows = all_active_signature_rows
    signature_rows = signature_rows.select { |row| row[:status_key] == @signature_status } if @signature_status.present?
    signature_rows = signature_rows.select { |row| row[:changed_recently] } if @signature_changes_only
    archived_rows = filter_archived_signature_rows(all_archived_signature_rows)
    changed_rows = all_signature_rows.select { |row| row[:changed_recently] }
    action_items = signature_rows.select { |row| row[:changed_recently] }
    recent_items = changed_rows.select { |row| finance_recent_unseen?(row[:occurred_at], seen_at) }

    {
      key: "signatures",
      label: "En cours de signature",
      icon: "fa-signature",
      task_count: changed_rows.count,
      unseen_count: recent_items.count,
      headline: "Tous les contrats envoyés par Claire, avec un état de signature détaillé.",
      description: "Affichage temporaire seedé avant le branchement API Yousign, avec statuts, relances et notes de suivi.",
      action_items: action_items,
      recent_items: recent_items,
      rows: signature_rows,
      changed_rows: changed_rows,
      metrics: signature_metrics_for(all_rows),
      archived_rows: archived_rows,
      archived_client_options: all_archived_signature_rows.map { |row| row[:client_name] }.uniq.sort,
      status_options: all_rows.map { |row| [ row[:status_label], row[:status_key] ] }.uniq,
      empty_action_label: "Aucune signature en attente.",
      empty_recent_label: "Aucun changement récent sur les signatures."
    }
  end

  def signature_row_for(mission)
    meta = parse_meta(mission.search_constraints)
    signature_key = meta["signature_status"].to_s
    return if signature_key.blank?

    config = signature_status_catalog[signature_key] || signature_status_catalog["transmitted"]
    sent_on = begin
      Date.parse(meta["signature_sent_at"].to_s)
    rescue ArgumentError, TypeError
      mission.opened_at || mission.updated_at&.to_date || Date.current
    end
    timeline = parse_signature_timeline(meta["signature_timeline"])
    last_event_at = parse_timestamp(meta["signature_last_event_at"]) || timeline.last&.dig(:at)
    last_event_type = meta["signature_last_event_type"].to_s
    changed_recently = signature_change_event?(last_event_type) && last_event_at.present? && last_event_at >= 24.hours.ago
    sent_at = parse_timestamp(meta["signature_sent_at"]) || timeline.first&.dig(:at)
    signed_event = timeline.reverse.find { |event| event[:kind] == "signed" }
    engagement_stats = signature_engagement_stats(timeline)

    {
      id: "signature-row-#{mission.id}",
      mission: mission,
      status_key: signature_key,
      client_name: mission.client_contact.client.brand_name.presence || mission.client_contact.client.legal_name,
      client_logo: mission.client_contact.client.logo,
      contact_name: [ mission.client_contact.first_name, mission.client_contact.last_name ].compact.join(" "),
      mission_title: mission.title,
      sent_on: sent_on,
      status_label: config[:label],
      status_short_label: config[:short_label],
      status_tone: config[:tone],
      followup: meta["signature_followup"].presence || config[:followup],
      note: meta["signature_note"].presence || config[:note],
      action_required: config[:action_required],
      changed_recently: changed_recently,
      last_event_type: last_event_type,
      change_hint: signature_change_hint(last_event_type, last_event_at),
      sent_at: sent_at,
      signed_at: signed_event&.dig(:at),
      engagement_stats: engagement_stats,
      timeline: timeline,
      occurred_at: last_event_at || mission.updated_at || mission.created_at,
      archived_at: mission.closed_at
    }
  end

  def filter_archived_signature_rows(rows)
    filtered = rows
    filtered = filtered.select { |row| row[:client_name] == @signature_archive_client } if @signature_archive_client.present?
    filtered = filtered.select { |row| row[:mission_title].to_s.downcase.include?(@signature_archive_mission.downcase) } if @signature_archive_mission.present?
    if @signature_archive_date.present?
      filtered = filtered.select do |row|
        row[:sent_on].present? && row[:sent_on].strftime("%Y-%m-%d") == @signature_archive_date
      end
    end
    filtered
  end

  def build_placements_tab(seen_tabs)
    seen_at = finance_seen_at_for(seen_tabs, "placements")
    placement_rows = @placements.map { |placement| placement_row_for(placement) }
    active_rows = placement_rows.reject { |row| row[:stage_key] == :paid }
    archived_rows = placement_rows.select { |row| row[:stage_key] == :paid }
    filtered_rows = @placements_changes_only ? active_rows.select { |row| row[:changed_recently] } : active_rows
    action_items = @placements.select(&:workflow_in_progress?).first(5).map do |placement|
      {
        id: "placement-action-#{placement.id}",
        title: placement.mission.title,
        subtitle: [ placement.candidate.first_name, placement.candidate.last_name ].compact.join(" "),
        detail: "Le placement attend encore une validation Rivyr.",
        badge: "À valider",
        badge_tone: :amber,
        occurred_at: placement.updated_at,
        cta: { label: "Voir le placement", path: placement_path(placement), method: :get }
      }
    end

    recent_items = @placements.filter_map do |placement|
      event_time = placement.admin_reviewed_at || placement.updated_at
      next unless finance_recent_unseen?(event_time, seen_at)
      next if placement.workflow_in_progress?

      {
        id: "placement-recent-#{placement.id}",
        title: placement.workflow_validated? ? "Placement validé" : "Placement refusé",
        subtitle: placement.mission.title,
        detail: placement.admin_review_note.presence || "Le statut conformité du placement a changé.",
        badge: placement.workflow_validated? ? "Validé" : "Refusé",
        badge_tone: placement.workflow_validated? ? :green : :rose,
        occurred_at: event_time,
        cta: { label: "Voir le dossier", path: placement_path(placement), method: :get }
      }
    end.first(5)

    {
      key: "placements",
      label: "Placements",
      icon: "fa-briefcase",
      task_count: action_items.count,
      unseen_count: recent_items.count,
      headline: "Validation, conformité et avancement des dossiers placés.",
      description: "Une lecture opérationnelle des placements encore ouverts et des validations récentes.",
      rows: filtered_rows,
      archived_rows: archived_rows,
      metrics: placement_metrics_for(placement_rows),
      action_items: action_items,
      recent_items: recent_items,
      empty_action_label: "Aucun placement en attente d'action.",
      empty_recent_label: "Aucun changement récent sur les placements."
    }
  end

  def placement_row_for(placement)
    changed_at = placement.admin_reviewed_at || placement.updated_at
    stage_snapshot = placement_stage_snapshot(placement)

    {
      id: "placement-row-#{placement.id}",
      placement: placement,
      mission_title: placement.mission.title,
      client_name: placement.mission.client_contact.client.brand_name.presence || placement.mission.client_contact.client.legal_name,
      candidate_name: placement.candidate.display_name,
      amount_cents: placement.commission&.freelancer_share_cents.to_i,
      workflow_label: stage_snapshot[:label],
      workflow_tone: stage_snapshot[:tone],
      stage_key: stage_snapshot[:key],
      reviewed_at: placement.admin_reviewed_at,
      note: placement.admin_review_note.presence || "Aucune note Rivyr pour l'instant.",
      updated_at: placement.updated_at,
      changed_recently: changed_at.present? && changed_at >= 24.hours.ago,
      change_hint: changed_at.present? ? "Changement d'etat le #{I18n.l(changed_at, format: "%d/%m a %Hh%M")}" : nil
    }
  end

  def placement_stage_snapshot(placement)
    client_invoice = placement.client_invoice
    freelancer_invoice = placement.freelancer_invoice
    latest_payout = latest_payout_request_for(freelancer_invoice)
    payout_pending_or_approved = latest_payout&.status.in?(%w[pending approved])
    payout_paid = latest_payout&.status_paid?
    wallet_available = client_invoice&.status_paid? && freelancer_invoice.present? && !payout_pending_or_approved && !payout_paid

    return { key: :paid, label: "Payé", tone: :green } if payout_paid
    return { key: :in_payment, label: "En paiement", tone: :slate } if payout_pending_or_approved
    return { key: :wallet_available, label: "Virement wallet disponible", tone: :green } if wallet_available
    return { key: :freelancer_invoice_validated, label: "Validation facture freelance", tone: :slate } if freelancer_invoice.present?
    return { key: :client_payment_received, label: "Paiement client reçu", tone: :green } if client_invoice&.status_paid?
    return { key: :client_payment_started, label: "Paiement client", tone: :amber } if client_invoice&.status_issued?
    return { key: :client_invoice_validated, label: "Facture validée", tone: :slate } if client_invoice&.issue_date.present?
    return { key: :client_invoice_created, label: "Création facture client", tone: :amber } if client_invoice.present?
    return { key: :documents_validated, label: "Documents validés", tone: :green } if placement.workflow_validated? || placement.mission.contract_signed?
    return { key: :refused, label: "Refusé", tone: :rose } if placement.workflow_refused?

    { key: :placement_realized, label: "Placement réalisé", tone: :amber }
  end

  def latest_payout_request_for(freelancer_invoice)
    freelancer_invoice&.payout_requests&.order(requested_at: :desc, created_at: :desc)&.first
  end

  def placement_metrics_for(rows)
    validated_count = rows.count { |row| row[:placement].workflow_validated? }
    in_progress_count = rows.count { |row| row[:placement].workflow_in_progress? }
    total_amount_cents = rows.select { |row| row[:placement].workflow_in_progress? }.sum { |row| row[:amount_cents].to_i }
    latest_review_at = rows.filter_map { |row| row[:reviewed_at] || row[:updated_at] }.max

    {
      validated_count: validated_count,
      in_progress_count: in_progress_count,
      total_amount_cents: total_amount_cents,
      latest_review_label: latest_review_at.present? ? I18n.l(latest_review_at.to_date, format: "%d/%m/%Y") : "-"
    }
  end

  def build_payments_tab(seen_tabs)
    seen_at = finance_seen_at_for(seen_tabs, "payments")
    all_rows = payment_history_rows(seen_at)
    rows = all_rows
    rows = rows.select { |row| row[:status_key] == @payment_status } if @payment_status.present?
    rows = rows.select { |row| row[:status_key] == "payout_pending" } if @payment_changes_only
    changed_rows = all_rows.select { |row| row[:changed_recently] }
    action_items = all_rows.select { |row| row[:status_key] == "payout_pending" }.first(5).map do |row|
      {
        id: row[:id],
        title: row[:mission_title],
        subtitle: row[:client_name],
        detail: row[:note],
        badge: row[:status_label],
        badge_tone: row[:status_tone],
        occurred_at: row[:occurred_at],
        cta: { label: "Voir le placement", path: placement_path(row[:placement]), method: :get }
      }
    end
    recent_items = all_rows.select { |row| row[:changed_recently] }.first(5)

    {
      key: "payments",
      label: "Paiements",
      icon: "fa-wallet",
      task_count: action_items.count,
      unseen_count: recent_items.count,
      headline: "Facturation, encaissement et disponibilité wallet dans une seule vue.",
      description: "Les actions finance prioritaires et les mouvements récents encore non consultés.",
      action_items: action_items,
      recent_items: recent_items,
      rows: rows,
      changed_rows: changed_rows,
      status_options: all_rows.map { |row| [ row[:status_label], row[:status_key] ] }.uniq,
      metrics: payment_metrics_for(all_rows),
      empty_action_label: "Aucune action paiement en attente.",
      empty_recent_label: "Aucun changement récent côté paiements."
    }
  end

  def payment_history_rows(seen_at)
    base_placements = @placements.first(8)
    return [] if base_placements.empty?

    history_blueprint = [
      { amount_cents: 200_000, date: Date.current - 2.days, status_key: "payout_pending", status_label: "En attente de paiement", status_tone: :amber, note: "Demande validée par Rivyr, virement en préparation." },
      { amount_cents: 1_500_00, date: Date.current - 18.days, status_key: "payout_paid", status_label: "Payé", status_tone: :green, note: "Virement exécuté par Rivyr." },
      { amount_cents: 2_000_00, date: Date.current - 41.days, status_key: "payout_paid", status_label: "Payé", status_tone: :green, note: "Paiement reçu sur le compte freelance." },
      { amount_cents: 2_500_00, date: Date.current - 67.days, status_key: "payout_paid", status_label: "Payé", status_tone: :green, note: "Virement mensuel confirmé." },
      { amount_cents: 1_500_00, date: Date.current - 94.days, status_key: "payout_paid", status_label: "Payé", status_tone: :green, note: "Paiement Rivyr envoyé et rapproché." },
      { amount_cents: 2_000_00, date: Date.current - 126.days, status_key: "payout_paid", status_label: "Payé", status_tone: :green, note: "Virement traité sans incident." },
      { amount_cents: 2_500_00, date: Date.current - 158.days, status_key: "payout_paid", status_tone: :green, status_label: "Payé", note: "Paiement exécuté sur le mois." },
      { amount_cents: 2_000_00, date: Date.current - 191.days, status_key: "payout_paid", status_label: "Payé", status_tone: :green, note: "Historique de paiement Rivyr." }
    ]

    history_blueprint.each_with_index.map do |entry, index|
      placement = base_placements[index % base_placements.size]
      event_time = entry[:date].to_time.change(hour: 10, min: 30)
      changed_recently = finance_recent_unseen?(event_time, seen_at)

      {
        id: "payment-row-history-#{placement.id}-#{index}",
        placement: placement,
        mission: placement.mission,
        client_name: placement.mission.client_contact.client.brand_name.presence || placement.mission.client_contact.client.legal_name,
        client_logo: placement.mission.client_contact.client.logo,
        mission_title: placement.mission.title,
        invoice_number: "RIV-PAY-2026-#{format('%03d', index + 1)}",
        amount_cents: entry[:amount_cents],
        status_key: entry[:status_key],
        status_label: entry[:status_label],
        status_short_label: entry[:status_label],
        status_tone: entry[:status_tone],
        note: entry[:note],
        occurred_at: event_time,
        changed_recently: changed_recently,
        change_hint: changed_recently ? "#{entry[:status_label]} mis à jour le #{I18n.l(event_time, format: "%d/%m à %Hh%M")}" : nil
      }
    end
  end

  def payment_metrics_for(rows)
    {
      pending_count: rows.count { |row| row[:status_key] == "payout_pending" },
      paid_count: rows.count { |row| row[:status_key] == "payout_paid" },
      paid_total_cents: rows.select { |row| row[:status_key] == "payout_paid" }.sum { |row| row[:amount_cents].to_i },
      task_tone: signature_task_tone(rows.select { |row| row[:changed_recently] })
    }
  end

  def payment_action_item_for(placement)
    client_invoice = placement.client_invoice
    freelancer_invoice = placement.freelancer_invoice
    commission_cents = placement.commission&.freelancer_share_cents.to_i
    latest_payout = freelancer_invoice&.payout_requests&.max_by { |request| request.updated_at || request.requested_at || Time.at(0) }

    if client_invoice.blank?
      {
        id: "payment-action-client-invoice-#{placement.id}",
        title: placement.mission.title,
        subtitle: "Facturation client",
        detail: "La facture client n'a pas encore été créée.",
        badge: "À facturer",
        badge_tone: :amber,
        occurred_at: placement.updated_at,
        cta: { label: "Créer la facture client", path: create_client_invoice_freelance_finance_path, method: :post, params: { placement_id: placement.id } }
      }
    elsif client_invoice.status_paid? && freelancer_invoice.blank? && commission_cents.positive?
      {
        id: "payment-action-freelancer-invoice-#{placement.id}",
        title: placement.mission.title,
        subtitle: "Facturation freelance",
        detail: "Le client a payé. La facture freelance peut être émise.",
        badge: "À émettre",
        badge_tone: :rose,
        occurred_at: client_invoice.updated_at || client_invoice.created_at,
        cta: { label: "Créer la facture freelance", path: create_freelancer_invoice_freelance_finance_path, method: :post, params: { placement_id: placement.id } }
      }
    elsif client_invoice.status_paid? && freelancer_invoice.present? && latest_payout.blank?
      {
        id: "payment-action-wallet-#{placement.id}",
        title: placement.mission.title,
        subtitle: "Wallet disponible",
        detail: "Le montant est disponible dans le wallet et peut être demandé en paiement.",
        badge: "Disponible",
        badge_tone: :green,
        occurred_at: freelancer_invoice.updated_at || freelancer_invoice.created_at,
        cta: {
          label: "Demander le paiement",
          path: create_payout_request_freelance_finance_path,
          method: :post,
          params: {
            invoice_id: freelancer_invoice.id,
            amount_cents: freelancer_invoice.amount_cents,
            billing_number: freelancer_invoice.number
          }
        }
      }
    elsif client_invoice.status_issued? && !client_invoice.status_paid?
      {
        id: "payment-action-followup-#{placement.id}",
        title: placement.mission.title,
        subtitle: "Encaissement client",
        detail: "Le paiement client est toujours attendu.",
        badge: "En attente",
        badge_tone: :slate,
        occurred_at: client_invoice.updated_at || client_invoice.created_at,
        cta: { label: "Voir le placement", path: placement_path(placement), method: :get }
      }
    end
  end

  def recent_payment_events(seen_at)
    events = []

    @placements.each do |placement|
      client_invoice = placement.client_invoice
      freelancer_invoice = placement.freelancer_invoice

      if client_invoice.present? && finance_recent_unseen?(client_invoice.updated_at || client_invoice.created_at, seen_at)
        events << {
          id: "payment-recent-client-invoice-#{placement.id}",
          title: client_invoice.status_paid? ? "Paiement client reçu" : "Facture client mise à jour",
          subtitle: placement.mission.title,
          detail: client_invoice.status_paid? ? "Le règlement client a été confirmé." : "La facture client a changé de statut.",
          badge: client_invoice.status_paid? ? "Payé" : "Suivi",
          badge_tone: client_invoice.status_paid? ? :green : :slate,
          occurred_at: client_invoice.updated_at || client_invoice.created_at,
          cta: { label: "Voir le placement", path: placement_path(placement), method: :get }
        }
      end

      client_invoice&.invoice_notes&.each do |note|
        next unless finance_recent_unseen?(note.created_at, seen_at)

        events << {
          id: "payment-recent-note-#{note.id}",
          title: note.action_required && note.resolved_at.blank? ? "Action demandée" : "Note Rivyr",
          subtitle: placement.mission.title,
          detail: note.body,
          badge: note.action_required && note.resolved_at.blank? ? "Action" : "Info",
          badge_tone: note.action_required && note.resolved_at.blank? ? :rose : :slate,
          occurred_at: note.created_at,
          cta: { label: "Voir le placement", path: placement_path(placement), method: :get }
        }
      end

      freelancer_invoice&.payout_requests&.each do |request|
        event_time = request.updated_at || request.requested_at
        next unless finance_recent_unseen?(event_time, seen_at)

        events << {
          id: "payment-recent-payout-#{request.id}",
          title: "Demande de virement #{request.status}",
          subtitle: placement.mission.title,
          detail: "Référence #{request.billing_number}",
          badge: request.status_paid? ? "Payé" : request.status.humanize,
          badge_tone: request.status_paid? ? :green : :rose,
          occurred_at: event_time,
          cta: { label: "Voir le placement", path: placement_path(placement), method: :get }
        }
      end
    end

    events.sort_by { |event| event[:occurred_at] || Time.at(0) }.reverse
  end

  def finance_recent_unseen?(event_time, seen_at)
    event_time.present? && event_time >= 24.hours.ago && event_time > seen_at
  end

  def parse_meta(raw_value)
    raw_value.to_s.split("||").each_with_object({}) do |chunk, hash|
      key, value = chunk.split("=", 2)
      next if key.blank? || value.blank?

      hash[key.strip] = value.strip
    end
  end

  def parse_signature_timeline(raw_value)
    raw_value.to_s.split(";;").filter_map do |entry|
      timestamp, middle, tail = entry.split("::", 3)
      label = tail.presence || middle
      kind = tail.present? ? middle : "note"
      next if timestamp.blank? || label.blank?

      parsed_at = parse_timestamp(timestamp)
      next if parsed_at.blank?

      { at: parsed_at, kind: kind.to_s, label: label.tr("_", " ") }
    end.sort_by { |item| item[:at] }
  end

  def parse_timestamp(raw_value)
    return if raw_value.blank?

    Time.zone.parse(raw_value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def signature_change_event?(event_type)
    %w[status_change followup].include?(event_type.to_s)
  end

  def signature_change_hint(event_type, event_time)
    base_label =
      case event_type.to_s
      when "status_change"
        "Changement de statut"
      when "followup"
        "Relance envoyée"
      else
        "Mise à jour récente"
      end

    return base_label if event_time.blank?

    "#{base_label} le #{I18n.l(event_time, format: "%d/%m à %Hh%M")}"
  end

  def signature_engagement_stats(timeline)
    {
      email_opened: timeline.count { |event| event[:kind] == "email_opened" },
      link_clicked: timeline.count { |event| event[:kind] == "link_clicked" },
      signature_redirect: timeline.count { |event| event[:kind] == "signature_redirect" }
    }
  end

  def signature_metrics_for(rows)
    current_year = Date.current.year
    yearly_rows = rows.select { |row| row[:sent_on].present? && row[:sent_on].year == current_year }
    previous_year_rows = rows.select { |row| row[:sent_on].present? && row[:sent_on].year == current_year - 1 }
    signed_rows = yearly_rows.select { |row| row[:status_key] == "signed" && row[:signed_at].present? && row[:sent_at].present? }
    previous_signed_rows = previous_year_rows.select { |row| row[:status_key] == "signed" && row[:signed_at].present? && row[:sent_at].present? }
    average_signature_delay_hours =
      if signed_rows.any?
        signed_rows.sum { |row| ((row[:signed_at] - row[:sent_at]) / 1.hour).to_f } / signed_rows.count
      else
        0
      end
    previous_average_signature_delay_hours =
      if previous_signed_rows.any?
        previous_signed_rows.sum { |row| ((row[:signed_at] - row[:sent_at]) / 1.hour).to_f } / previous_signed_rows.count
      else
        0
      end
    current_conversion_rate = yearly_rows.any? ? ((yearly_rows.count { |row| row[:status_key] == "signed" }.to_f / yearly_rows.count) * 100) : 0
    previous_conversion_rate = previous_year_rows.any? ? ((previous_year_rows.count { |row| row[:status_key] == "signed" }.to_f / previous_year_rows.count) * 100) : 0
    monthly_sent_series = build_signature_monthly_sent_series(rows, current_year)
    average_contracts_per_month = Date.current.month.positive? ? (yearly_rows.count.to_f / Date.current.month) : 0
    average_signature_delay_days = average_signature_delay_hours / 24.0

    {
      conversion_rate: current_conversion_rate.round,
      conversion_trend: signature_trend_data(current_conversion_rate, previous_conversion_rate, positive_when_up: true, unit: "pts"),
      conversion_tone: signature_conversion_tone(current_conversion_rate),
      yearly_sent_count: yearly_rows.count,
      yearly_sent_trend: signature_trend_data(yearly_rows.count, previous_year_rows.count, positive_when_up: true),
      yearly_sent_tone: signature_yearly_sent_tone(average_contracts_per_month),
      monthly_sent_series: monthly_sent_series,
      average_signature_delay: average_signature_delay_hours.positive? ? "#{average_signature_delay_days.round(1)} j" : "-",
      average_signature_delay_trend: signature_trend_data(average_signature_delay_hours, previous_average_signature_delay_hours, positive_when_up: false, unit: "h"),
      average_signature_delay_tone: signature_delay_tone(average_signature_delay_days),
      changed_count: rows.count { |row| row[:changed_recently] },
      recent_count: rows.count { |row| row[:occurred_at].present? && row[:occurred_at] >= 24.hours.ago },
      task_tone: signature_task_tone(rows.select { |row| row[:changed_recently] })
    }
  end

  def build_signature_monthly_sent_series(rows, year)
    start_month = Date.current.beginning_of_month - 5.months

    6.times.map do |offset|
      month_date = start_month + offset.months
      count = rows.count do |row|
        row[:sent_on].present? && row[:sent_on].year == month_date.year && row[:sent_on].month == month_date.month
      end

      {
        label: I18n.l(month_date, format: "%b").first(1),
        count: count
      }
    end
  end

  def signature_trend_data(current_value, previous_value, positive_when_up:, unit: nil)
    delta = current_value.to_f - previous_value.to_f
    direction =
      if delta.positive?
        positive_when_up ? :up : :down
      elsif delta.negative?
        positive_when_up ? :down : :up
      else
        :flat
      end

    formatted_delta =
      if delta.zero?
        "Stable"
      else
        absolute_delta = delta.abs.round
        suffix = unit.present? ? " #{unit}" : ""
        "#{delta.positive? ? '+' : '-'}#{absolute_delta}#{suffix}"
      end

    {
      direction: direction,
      delta_label: formatted_delta
    }
  end

  def signature_conversion_tone(rate)
    return :rose if rate < 45
    return :amber if rate <= 75

    :green
  end

  def signature_yearly_sent_tone(average_per_month)
    return :rose if average_per_month < 1
    return :amber if average_per_month <= 2

    :green
  end

  def signature_delay_tone(days)
    return :green if days.positive? && days < 3
    return :amber if days <= 5

    :rose
  end

  def signature_task_tone(changed_rows)
    latest_event = changed_rows.filter_map { |row| row[:occurred_at] }.max
    return :slate if latest_event.blank?
    return :green if latest_event.to_date == Date.current
    return :amber if latest_event.to_date == Date.yesterday

    :rose
  end

  def signature_status_catalog
    {
      "transmitted" => {
        label: "Transmis",
        short_label: "Transmis",
        tone: :amber,
        action_required: true,
        followup: "Relance auto dans 24h",
        note: "Contrat transmis au client."
      },
      "client_signing" => {
        label: "En cours de signature client",
        short_label: "En cours",
        tone: :slate,
        action_required: false,
        followup: "Relance auto dans 48h",
        note: "Le client est en train de signer."
      },
      "client_changes_requested" => {
        label: "Modification client demandée",
        short_label: "Modif.",
        tone: :rose,
        action_required: true,
        followup: "Relance désactivée",
        note: "Le client demande un ajustement avant signature."
      },
      "signed" => {
        label: "Signé",
        short_label: "Signé",
        tone: :green,
        action_required: false,
        followup: "Relance désactivée",
        note: "Contrat signé par toutes les parties."
      },
      "refused" => {
        label: "Refusé",
        short_label: "Refusé",
        tone: :rose,
        action_required: true,
        followup: "Relance désactivée",
        note: "Le contrat a été refusé par le client."
      },
      "expired" => {
        label: "Délais dépassé",
        short_label: "Dépassé",
        tone: :slate,
        action_required: true,
        followup: "Relance auto dans 24h",
        note: "Le délai de signature est dépassé."
      }
    }
  end

  def finance_seen_tabs
    JSON.parse(cookies.signed[:freelance_finance_seen_tabs].presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def finance_seen_at_for(seen_tabs, key)
    value = seen_tabs[key].presence
    return Time.at(0) if value.blank?

    Time.zone.parse(value) || Time.at(0)
  rescue ArgumentError, TypeError
    Time.at(0)
  end

  def mark_finance_tab_seen!(tab_key)
    seen_tabs = finance_seen_tabs
    seen_tabs[tab_key] = Time.current.iso8601
    cookies.signed[:freelance_finance_seen_tabs] = {
      value: seen_tabs.to_json,
      expires: 6.months.from_now
    }
  end

  def estimated_mission_commission_cents(mission)
    salary = mission.compensation_summary.to_s.scan(/\d[\d\s]*/).map { |value| value.gsub(/\s/, "").to_i }.select(&:positive?)
    salary_average =
      if salary.empty?
        0
      elsif salary.one?
        salary.first
      else
        ((salary.first + salary[1]) / 2.0).round
      end

    ((salary_average * 0.20) * 0.60).round * 100
  end

  def finance_overview_data
    month_range = Date.current.beginning_of_month..Date.current.end_of_month
    monthly_revenue_cents = own_freelancer_invoices.where(issue_date: month_range).sum(:amount_cents)
    monthly_target_eur = @freelancer_profile&.monthly_revenue_target_for(Date.current).to_i
    signed_this_month = all_signature_rows.select do |row|
      row[:status_key] == "signed" && row[:signed_at].present? && row[:signed_at].to_date.in?(month_range)
    end
    sent_this_month = all_signature_rows.count { |row| row[:sent_on].present? && row[:sent_on].in?(month_range) }
    promised_payments_cents = signed_this_month.sum do |row|
      row[:mission].placement&.commission&.freelancer_share_cents.to_i.nonzero? || estimated_mission_commission_cents(row[:mission])
    end

    signature_actions = all_signature_rows
      .select { |row| row[:action_required] && row[:status_key] != "signed" }
      .sort_by { |row| row[:occurred_at] || Time.at(0) }
      .reverse
      .map do |row|
        {
          occurred_at: row[:occurred_at],
          text: "#{row[:client_name]} : #{row[:status_label]}"
        }
      end

    payment_actions = @placements.filter_map do |placement|
      item = payment_action_item_for(placement)
      next if item.blank?

      {
        occurred_at: item[:occurred_at],
        text: "#{item[:title]} : #{item[:badge]}"
      }
    end

    urgent_actions = (signature_actions + payment_actions)
      .sort_by { |item| item[:occurred_at] || Time.at(0) }
      .reverse
      .uniq { |item| item[:text] }

    raw_progress_percent =
      if monthly_target_eur.positive?
        ((monthly_revenue_cents / 100.0) / monthly_target_eur * 100).round
      else
        0
      end

    {
      current_month_label: month_label_fr(Date.current),
      monthly_revenue_cents: monthly_revenue_cents,
      monthly_target_eur: monthly_target_eur,
      annual_target_eur: @freelancer_profile&.annual_revenue_target_eur.to_i,
      progress_percent: raw_progress_percent,
      progress_bar_percent: [ raw_progress_percent, 100 ].min,
      signed_this_month_count: signed_this_month.count,
      sent_this_month_count: sent_this_month,
      promised_payments_cents: promised_payments_cents,
      freelance_legal_status_label: @freelancer_profile&.freelance_legal_status_label || "Non renseigne",
      urgent_actions: urgent_actions.first(3),
      urgent_actions_count: urgent_actions.count
    }
  end

  def month_label_fr(date)
    month_names = [
      nil, "janvier", "fevrier", "mars", "avril", "mai", "juin",
      "juillet", "aout", "septembre", "octobre", "novembre", "decembre"
    ]

    "#{month_names[date.month]} #{date.year}"
  end

  def yearly_revenue_snapshot
    year = Date.current.year
    invoices = own_freelancer_invoices.where(issue_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
    projected_cents = @placements.sum { |placement| placement.commission&.freelancer_share_cents.to_i }

    {
      year: year,
      placements_count: @placements.count,
      realized_cents: paid_out_cents,
      pending_cents: [ activated_commissions_cents - paid_out_cents, 0 ].max,
      projected_cents: projected_cents
    }
  end

  def build_upcoming_payments(placements)
    placements.map do |placement|
      client_invoice = placement.client_invoice
      freelancer_invoice = placement.freelancer_invoice
      latest_payout = freelancer_invoice&.payout_requests&.order(requested_at: :desc)&.first

      status_label =
        if client_invoice.blank?
          "Facturation client a lancer"
        elsif client_invoice.status_paid?
          if latest_payout&.status_paid?
            "Paye par Rivyr"
          elsif latest_payout.present?
            "Virement Rivyr en traitement"
          elsif freelancer_invoice.present?
            "Facture freelance emise"
          else
            "Paye client, facture freelance a emettre"
          end
        else
          "Paiement client attendu"
        end

      {
        placement: placement,
        mission_title: placement.mission.title,
        client_name: placement.mission.client_contact.client.legal_name,
        amount_cents: placement.commission&.freelancer_share_cents.to_i,
        estimated_date: client_invoice&.paid_date || client_invoice&.issue_date || placement.hired_at,
        status_label: status_label
      }
    end
  end

  def build_active_payment_missions(placements)
    placements.filter_map do |placement|
      client_invoice = placement.client_invoice
      commission_amount = placement.commission&.freelancer_share_cents.to_i
      next if commission_amount <= 0

      stage =
        if placement.freelancer_invoice&.payout_requests&.where(status: "paid")&.exists?
          4
        elsif placement.freelancer_invoice&.payout_requests&.where(status: [ "pending", "approved" ])&.exists?
          3
        elsif placement.freelancer_invoice.present?
          3
        elsif client_invoice&.status_paid?
          2
        elsif client_invoice.present?
          1
        else
          0
        end

      {
        placement: placement,
        mission_title: placement.mission.title,
        client_name: placement.mission.client_contact.client.legal_name,
        amount_cents: commission_amount,
        stage: stage,
        progress_percent: (stage * 25),
        client_paid_at: client_invoice&.paid_date
      }
    end
  end

  def build_finance_feed(placements)
    events = []

    placements.each do |placement|
      invoice = placement.client_invoice
      if invoice
        invoice.invoice_notes.order(created_at: :desc).limit(2).each do |note|
          events << {
            type: note.action_required && note.resolved_at.blank? ? "action" : "note",
            date: note.created_at,
            message: note.body
          }
        end
      end

      latest_payout = placement.freelancer_invoice&.payout_requests&.order(requested_at: :desc)&.first
      if latest_payout
        events << {
          type: latest_payout.status_paid? ? "success" : "note",
          date: latest_payout.requested_at,
          message: "Demande de virement #{latest_payout.status} (#{latest_payout.billing_number})"
        }
      end
    end

    events.sort_by { |event| event[:date] }.reverse.first(6)
  end

  def monthly_gross_series(invoices)
    (0..11).map do |offset|
      month_start = (Date.current.beginning_of_month - offset.months).beginning_of_month
      month_end = month_start.end_of_month
      {
        label: month_start.strftime("%b %Y"),
        amount_cents: invoices.where(issue_date: month_start..month_end).sum(:amount_cents)
      }
    end.reverse
  end

  def next_invoice_number(prefix)
    date_part = Date.current.strftime("%Y%m%d")
    loop do
      candidate = "#{prefix}-#{date_part}-#{SecureRandom.hex(3).upcase}"
      return candidate unless Invoice.exists?(number: candidate)
    end
  end
end
