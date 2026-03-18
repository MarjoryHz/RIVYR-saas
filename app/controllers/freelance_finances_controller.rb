class FreelanceFinancesController < ApplicationController
  before_action :set_placements_scope

  def show
    authorize :freelance_finance, :show?
    @tab = params[:tab].presence_in(%w[signatures placements payments]) || "signatures"
    @wallet_tab = params[:wallet_tab].presence_in(%w[available waiting potential]) || "available"
    @signature_status = params[:signature_status].presence_in(%w[transmitted client_signing client_changes_requested signed refused expired]).to_s
    @signature_archive_client = params[:signature_archive_client].to_s.strip
    @signature_archive_mission = params[:signature_archive_mission].to_s.strip
    @signature_archive_date = params[:signature_archive_date].to_s.strip
    @signature_changes_only = params[:signature_changes_only].to_s == "1"
    @q = params[:q].to_s.strip
    @client_invoice_status = params[:client_invoice_status].to_s.strip
    @payout_status = params[:payout_status].to_s.strip
    @action_required = params[:action_required].to_s == "1"

    @missions = finance_missions_scope
    @placements = filtered_placements
    @available_wallet_cents = available_wallet_cents
    @waiting_client_payments_cents = waiting_client_payments_cents
    @potential_wallet_cents = potential_wallet_cents

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
    amount_cents = params[:amount_cents].to_i
    amount_cents = invoice.amount_cents if amount_cents <= 0

    if amount_cents > available_wallet_cents
      return redirect_to dashboard_freelance_finance_path, alert: "Montant supérieur au portefeuille disponible."
    end

    if current_user.payout_requests.where(invoice: invoice, status: [ "pending", "approved" ]).exists?
      return redirect_to dashboard_freelance_finance_path, alert: "Une demande de virement est déjà en cours pour cette facture."
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
    all_signature_rows = @missions.filter_map { |mission| signature_row_for(mission) }
    all_archived_signature_rows = finance_archived_missions_scope.filter_map { |mission| signature_row_for(mission) }
    all_rows = all_signature_rows + all_archived_signature_rows
    signature_rows = all_signature_rows
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
      action_items: action_items,
      recent_items: recent_items,
      empty_action_label: "Aucun placement en attente d'action.",
      empty_recent_label: "Aucun changement récent sur les placements."
    }
  end

  def build_payments_tab(seen_tabs)
    seen_at = finance_seen_at_for(seen_tabs, "payments")
    action_items = @placements.filter_map { |placement| payment_action_item_for(placement) }.first(5)
    recent_items = recent_payment_events(seen_at).first(5)

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
      empty_action_label: "Aucune action paiement en attente.",
      empty_recent_label: "Aucun changement récent côté paiements."
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
