class FreelanceFinancesController < ApplicationController
  before_action :set_placements_scope

  def show
    authorize :freelance_finance, :show?

    @q = params[:q].to_s.strip
    @client_invoice_status = params[:client_invoice_status].to_s.strip
    @action_required = params[:action_required].to_s == "1"
    @payout_status = params[:payout_status].to_s.strip

    @placements = filtered_placements
    @payout_requests = filtered_payout_requests

    @wallet_cents = available_wallet_cents
    @reserved_payout_cents = reserved_payout_cents
    @paid_out_cents = paid_out_cents
    @kpis = gross_kpis
    @max_monthly_cents = [ @kpis[:monthly].map { |item| item[:amount_cents] }.max.to_i, 1 ].max

    @waiting_client_payments_cents = waiting_client_payments_cents
    @yearly_revenue = yearly_revenue_snapshot
    @upcoming_payments = build_upcoming_payments(@placements.first(5))
    @active_payment_missions = build_active_payment_missions(@placements.first(3))
    @finance_feed = build_finance_feed(@placements.first(10))
  end

  def create_client_invoice
    authorize :freelance_finance, :create_client_invoice?

    placement = @placements_scope.find(params[:placement_id])
    if placement.client_invoice.present?
      return redirect_to freelance_finance_path, alert: "Une facture client existe deja pour ce placement."
    end

    invoice = placement.invoices.new(
      invoice_type: "client",
      number: next_invoice_number("RIV-CLI"),
      status: "issued",
      issue_date: Date.current,
      amount_cents: placement.placement_fee_cents.to_i
    )

    if invoice.save
      redirect_to freelance_finance_path, notice: "Facture client generee et transmise a Rivyr pour suivi."
    else
      redirect_to freelance_finance_path, alert: invoice.errors.full_messages.to_sentence
    end
  end

  def create_freelancer_invoice
    authorize :freelance_finance, :create_freelancer_invoice?

    placement = @placements_scope.find(params[:placement_id])
    if placement.freelancer_invoice.present?
      return redirect_to freelance_finance_path, alert: "Une facture freelance existe deja pour ce placement."
    end

    unless placement.client_invoice&.status_paid?
      return redirect_to freelance_finance_path, alert: "La facture client doit etre encaissee par Rivyr avant facturation freelance."
    end

    commission_amount = placement.commission&.freelancer_share_cents.to_i
    if commission_amount <= 0
      return redirect_to freelance_finance_path, alert: "Aucune commission freelance disponible pour ce placement."
    end

    invoice = placement.invoices.new(
      invoice_type: "freelancer",
      number: next_invoice_number("FRL"),
      status: "issued",
      issue_date: Date.current,
      amount_cents: commission_amount
    )

    if invoice.save
      redirect_to freelance_finance_path, notice: "Facture freelance creee avec succes."
    else
      redirect_to freelance_finance_path, alert: invoice.errors.full_messages.to_sentence
    end
  end

  def create_payout_request
    authorize :freelance_finance, :create_payout_request?

    invoice = own_freelancer_invoices.find(params[:invoice_id])
    amount_cents = params[:amount_cents].to_i
    amount_cents = invoice.amount_cents if amount_cents <= 0

    if amount_cents > available_wallet_cents
      return redirect_to freelance_finance_path, alert: "Montant superieur au portefeuille disponible."
    end

    if current_user.payout_requests.where(invoice: invoice, status: [ "pending", "approved" ]).exists?
      return redirect_to freelance_finance_path, alert: "Une demande de virement est deja en cours pour cette facture."
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
      redirect_to freelance_finance_path, notice: "Demande de virement envoyee a Rivyr."
    else
      redirect_to freelance_finance_path, alert: payout_request.errors.full_messages.to_sentence
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
