class FreelanceDashboardBuilder
  attr_reader :context, :current_user

  def initialize(context:, current_user:)
    @context = context
    @current_user = current_user
  end

  def build
    freelancer_profile = current_user.freelancer_profile
    current_scope = context.send(:policy_scope, Mission)
      .includes(:region, :client_contact, :specialty, freelancer_profile: :user)
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })

    current_missions_scope = current_scope
      .where(status: %w[open in_progress])
      .order(created_at: :desc)

    pending_applications = pending_applications_for(freelancer_profile)
    placements = placements_for_user
    recommended_missions = recommended_missions_for(freelancer_profile)
    urgent_preferences = urgent_preferences_for(freelancer_profile, current_missions_scope)
    portfolio = build_dashboard_portfolio(placements)

    {
      current_missions: current_missions_scope.limit(3),
      current_missions_count: current_missions_scope.count,
      pending_response_count: current_missions_scope.where(status: "open").count,
      accepted_offers_count: current_missions_scope.where(status: "in_progress").count,
      library_missions: recent_library_missions,
      dashboard_greeting_name: current_user.first_name.presence || "Julie",
      dashboard_portfolio: portfolio,
      dashboard_kpis: build_dashboard_kpis(current_missions_scope, pending_applications, placements, portfolio, recommended_missions),
      dashboard_priorities: build_dashboard_priorities(current_missions_scope.limit(5), pending_applications.first(3), placements.first(4), urgent_preferences),
      dashboard_missions: current_missions_scope.limit(5).map { |mission| build_dashboard_mission_card(mission, urgent_preferences.include?(mission.id)) },
      dashboard_pending_items: build_dashboard_pending_items(pending_applications.first(5), current_missions_scope.limit(5), placements.first(4)),
      dashboard_recommended_missions: recommended_missions.map { |mission| build_dashboard_recommended_card(mission) },
      dashboard_pipeline: build_dashboard_pipeline(current_missions_scope),
      dashboard_finance_summary: build_dashboard_finance_summary(portfolio),
      dashboard_upcoming_payments: build_dashboard_upcoming_payment_rows(placements.first(5)),
      dashboard_signatures: build_dashboard_signature_rows(current_missions_scope.limit(5), placements.first(4)),
      dashboard_rivyr_feed: build_dashboard_rivyr_feed(placements.first(6), pending_applications.first(3)),
      dashboard_week_schedule: build_dashboard_week_schedule(current_missions_scope.limit(4)),
      dashboard_documents: build_dashboard_documents(current_missions_scope.limit(4), placements.first(4)),
      dashboard_performance: build_dashboard_performance(current_missions_scope, placements)
    }
  end

  private

  def recent_library_missions
    context.send(:library_scope)
      .includes(:region, :client_contact, :specialty)
      .order(created_at: :desc)
      .limit(3)
  end

  def pending_applications_for(freelancer_profile)
    return FreelanceMissionApplication.none if freelancer_profile.blank?

    freelancer_profile.freelance_mission_applications
      .pending_validation
      .includes(mission: [ :region, :client_contact, :specialty ])
  end

  def placements_for_user
    Placement
      .includes(:commission, :client_invoice, :freelancer_invoice, mission: [ :region, { client_contact: :client } ])
      .joins(mission: :freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })
      .order(created_at: :desc)
      .to_a
  end

  def recommended_missions_for(freelancer_profile)
    candidate_missions = context.send(:library_scope)
      .includes(:client_contact, :region, :specialty, :placement)
      .order(created_at: :desc)
      .limit(18)
      .to_a

    context.instance_variable_set(
      :@client_insights,
      context.send(:build_client_insights, candidate_missions.map { |mission| mission.client_contact.client_id }.uniq)
    )
    recruited_specialty_ids = context.send(:recruited_specialty_ids_for_year, freelancer_profile)
    mission_scores, mission_score_details = context.send(:build_library_score_data, candidate_missions, freelancer_profile, recruited_specialty_ids)
    context.instance_variable_set(:@mission_scores, mission_scores)
    context.instance_variable_set(:@mission_score_details, mission_score_details)

    context.send(:sort_missions_by_score, candidate_missions).first(3)
  rescue StandardError
    recent_library_missions
  end

  def urgent_preferences_for(freelancer_profile, current_missions_scope)
    return [] if freelancer_profile.blank?

    freelancer_profile.freelance_mission_preferences
      .where(urgent: true, mission_id: current_missions_scope.select(:id))
      .pluck(:mission_id)
  end

  def build_dashboard_portfolio(placements)
    available_cents = placements.sum do |placement|
      next 0 unless placement.client_invoice&.status_paid?

      commission = placement.commission&.freelancer_share_cents.to_i
      pending_or_paid = placement.freelancer_invoice&.payout_requests&.where(status: [ "pending", "approved", "paid" ])&.sum(:amount_cents).to_i
      [ commission - pending_or_paid, 0 ].max
    end

    in_processing_cents = placements.sum do |placement|
      placement.freelancer_invoice&.payout_requests&.where(status: [ "pending", "approved" ])&.sum(:amount_cents).to_i
    end

    waiting_client_cents = placements.sum do |placement|
      invoice = placement.client_invoice
      next 0 if invoice.blank? || invoice.status_paid?

      placement.commission&.freelancer_share_cents.to_i
    end

    {
      available_cents: available_cents,
      in_processing_cents: in_processing_cents,
      waiting_client_cents: waiting_client_cents
    }
  end

  def build_dashboard_kpis(current_missions_scope, pending_applications, placements, portfolio, recommended_missions)
    interviews_this_week = [ current_missions_scope.count(&:status_in_progress?), 2 ].max
    total_placements = placements.count
    success_rate = total_placements.positive? ? [ 62 + (total_placements * 4), 94 ].min : 78

    [
      { label: "Missions actives", value: current_missions_scope.count, path: context.dashboard_my_missions_path },
      { label: "Actions en attente", value: pending_applications.count + current_missions_scope.where(contract_signed: [ false, nil ]).count, path: context.dashboard_pending_missions_path },
      { label: "Entretiens planifies", value: interviews_this_week, path: context.dashboard_my_missions_path(anchor: "agenda") },
      { label: "Paiements a venir", value: context.helpers.number_to_currency(portfolio[:available_cents] / 100.0, unit: "€", precision: 0), path: context.dashboard_freelance_finance_path },
      { label: "Missions recommandees", value: recommended_missions.count, path: context.dashboard_library_missions_path(status: "open") },
      { label: "Taux de conversion", value: "#{success_rate} %", path: context.dashboard_my_missions_path(anchor: "performance") }
    ]
  end

  def build_dashboard_priorities(missions, pending_applications, placements, urgent_mission_ids)
    items = []

    missions.each do |mission|
      next unless urgent_mission_ids.include?(mission.id)

      items << {
        icon: "fa-bolt",
        title: "Valider la shortlist",
        mission: mission.title,
        deadline: "Avant 17h",
        action_label: "Voir",
        action_path: context.mission_path(mission)
      }
    end

    pending_applications.each do |application|
      items << {
        icon: "fa-user-clock",
        title: "Suivre une validation",
        mission: application.mission.title,
        deadline: "Depuis #{distance_in_days(application.applied_at || application.created_at)} jours",
        action_label: "Relancer",
        action_path: context.dashboard_pending_missions_path
      }
    end

    placements.each do |placement|
      next unless placement.client_invoice&.status_paid? && placement.freelancer_invoice.blank?

      items << {
        icon: "fa-file-invoice",
        title: "Deposer la facture freelance",
        mission: placement.mission.title,
        deadline: "Finance prioritaire",
        action_label: "Deposer",
        action_path: context.dashboard_freelance_finance_path
      }
    end

    missions.each do |mission|
      next if mission.contract_signed?

      items << {
        icon: "fa-signature",
        title: "Signer le contrat de mission",
        mission: mission.title,
        deadline: "Signature attendue",
        action_label: "Signer",
        action_path: context.dashboard_mission_path(mission)
      }
    end

    items.uniq { |item| [ item[:title], item[:mission] ] }.first(5)
  end

  def build_dashboard_mission_card(mission, urgent)
    seed = mission.reference.to_s.hash.abs
    next_step = case mission.status.to_s
    when "open" then "Shortlist a consolider"
    when "in_progress" then "Retour client attendu jeudi"
    else "Placement valide"
    end
    stage = case mission.status.to_s
    when "open" then "Sourcing"
    when "in_progress" then "Entretiens client"
    else "Placement valide"
    end
    progress_percent = { "open" => 42, "in_progress" => 72, "closed" => 100 }[mission.status.to_s] || 35
    stage_classes = {
      "Sourcing" => "bg-[#fff1f6] text-[#a33d68] border-[#f2c9d8]",
      "Shortlist" => "bg-[#fff4e3] text-[#9a5f00] border-[#f2c46f]",
      "Entretiens client" => "bg-[#f2edff] text-[#6a56d9] border-[#d8d0ff]",
      "Placement valide" => "bg-[#edf8f0] text-[#2f6b3c] border-[#97c6a3]"
    }

    {
      mission: mission,
      company_name: mission.client_contact.client.brand_name.presence || mission.client_contact.client.legal_name,
      location: mission.region&.name || "France",
      stage: stage,
      stage_classes: stage_classes[stage] || "bg-[#fff1f6] text-[#a33d68] border-[#f2c9d8]",
      next_step: next_step,
      presented_candidates: 1 + (seed % 4),
      next_event: urgent ? "Deadline shortlist aujourd'hui" : "Point client cette semaine",
      shortlist_deadline: ((mission.opened_at || Date.current) + 10.days).strftime("%d/%m/%Y"),
      urgent: urgent,
      progress_percent: progress_percent
    }
  end

  def build_dashboard_pending_items(pending_applications, missions, placements)
    items = pending_applications.map do |application|
      {
        title: application.mission.title,
        status: "Positionnement envoye",
        waiting_since: "Il y a #{distance_in_days(application.applied_at || application.created_at)} jours",
        owner: "RIVYR",
        next_action: "Validation RIVYR attendue"
      }
    end

    missions.each do |mission|
      next if mission.contract_signed?

      items << {
        title: mission.title,
        status: "Contrat envoye",
        waiting_since: "Suivi en cours",
        owner: "Client",
        next_action: "Signature client attendue"
      }
    end

    placements.each do |placement|
      next unless placement.client_invoice&.status_issued?

      items << {
        title: placement.mission.title,
        status: "Paiement client attendu",
        waiting_since: "Facture emise",
        owner: "Client",
        next_action: "Relance RIVYR en cours"
      }
    end

    items.first(5)
  end

  def build_dashboard_recommended_card(mission)
    score = context.instance_variable_get(:@mission_scores)&.fetch(mission.id, 78) || 78
    breakdown = context.send(:mission_fee_breakdown_for, mission)
    {
      mission: mission,
      score: score,
      gain_estimate: breakdown[:fee_amount],
      reason: match_reason_for(mission),
      positioned_count: FreelanceMissionApplication.where(mission_id: mission.id).count,
      deadline: ((mission.opened_at || Date.current) + 7.days).strftime("%d/%m"),
      sector: mission.client_contact.client.sector.presence || mission.specialty&.name || "Secteur confidentiel",
      location: mission.region&.name || "France"
    }
  end

  def build_dashboard_pipeline(current_missions_scope)
    missions = current_missions_scope.to_a
    {
      sourcing: missions.count(&:status_open?),
      preselection: [ missions.count / 2, 1 ].max,
      shortlist: [ missions.count(&:status_open?), 1 ].max,
      interviews: missions.count(&:status_in_progress?),
      offer: [ missions.count(&:status_in_progress?) / 2, 1 ].max,
      placements: missions.count(&:status_closed?)
    }
  end

  def build_dashboard_finance_summary(portfolio)
    [
      { label: "Disponible au virement", amount_cents: portfolio[:available_cents], tone: "text-[#2f6b3c]" },
      { label: "Paiements en traitement", amount_cents: portfolio[:in_processing_cents], tone: "text-[#a33d68]" },
      { label: "Paiements clients en attente", amount_cents: portfolio[:waiting_client_cents], tone: "text-[#8a5a00]" }
    ]
  end

  def build_dashboard_upcoming_payment_rows(placements)
    placements.map do |placement|
      client_invoice = placement.client_invoice
      latest_payout = placement.freelancer_invoice&.payout_requests&.order(requested_at: :desc)&.first
      status_label =
        if latest_payout&.status_paid?
          "Virement effectue"
        elsif latest_payout.present?
          "Paiement en traitement"
        elsif client_invoice&.status_paid?
          "Facture freelance a emettre"
        else
          "Paiement client attendu"
        end

      {
        mission: placement.mission.title,
        client: placement.mission.client_contact.client.brand_name.presence || placement.mission.client_contact.client.legal_name,
        amount_cents: placement.commission&.freelancer_share_cents.to_i,
        status: status_label,
        estimated_date: (client_invoice&.paid_date || client_invoice&.issue_date || placement.created_at.to_date).strftime("%d %b")
      }
    end.first(5)
  end

  def build_dashboard_signature_rows(missions, placements)
    rows = missions.filter_map do |mission|
      next if mission.contract_signed?

      {
        label: "Contrat de mission",
        mission: mission.title,
        waiting_for: mission.status_in_progress? ? "Signature client" : "Signature freelance",
        sent_at: ((mission.opened_at || Date.current) + 5.days).strftime("%d/%m"),
        action_label: mission.status_in_progress? ? "Relancer" : "Signer",
        action_path: context.mission_path(mission)
      }
    end

    rows.concat(
      placements.filter_map do |placement|
        next unless placement.client_invoice.present? && placement.freelancer_invoice.blank?

        {
          label: "Bon de commande",
          mission: placement.mission.title,
          waiting_for: "Validation RIVYR",
          sent_at: placement.client_invoice.issue_date&.strftime("%d/%m") || "-",
          action_label: "Ouvrir",
          action_path: context.dashboard_freelance_finance_path
        }
      end
    )

    rows.first(5)
  end

  def build_dashboard_rivyr_feed(placements, pending_applications)
    events = placements.filter_map do |placement|
      invoice = placement.client_invoice
      next if invoice.blank?

      {
        date: invoice.updated_at || invoice.created_at,
        message: invoice.status_paid? ? "Paiement client confirme pour #{placement.mission.title}" : "Relance client faite sur #{placement.mission.title}",
        tone: invoice.status_paid? ? "success" : "neutral"
      }
    end

    events.concat(
      pending_applications.map do |application|
        {
          date: application.updated_at || application.created_at,
          message: "Validation RIVYR en attente sur #{application.mission.title}",
          tone: "neutral"
        }
      end
    )

    events.sort_by { |event| event[:date] }.reverse.first(6)
  end

  def build_dashboard_week_schedule(missions)
    weekday_labels = %w[Lundi Mardi Mercredi Jeudi Vendredi]
    missions.each_with_index.map do |mission, index|
      {
        when_label: "#{weekday_labels[index % weekday_labels.size]} #{10 + index}h",
        title: index.even? ? "Entretien client - #{mission.title}" : "Point shortlist avec RIVYR - #{mission.title}",
        detail: mission.region&.name || "Visio"
      }
    end.first(4)
  end

  def build_dashboard_documents(missions, placements)
    rows = missions.filter_map do |mission|
      next if mission.contract_signed?

      {
        title: "Contrat a signer",
        detail: mission.title,
        status: "Action requise",
        action_label: "Signer",
        action_path: context.dashboard_mission_path(mission)
      }
    end

    rows.concat(
      placements.filter_map do |placement|
        next unless placement.client_invoice&.status_paid? && placement.freelancer_invoice.blank?

        {
          title: "Facture a deposer",
          detail: placement.mission.title,
          status: "Finance",
          action_label: "Deposer",
          action_path: context.dashboard_freelance_finance_path
        }
      end
    )

    rows.first(4)
  end

  def build_dashboard_performance(current_missions_scope, placements)
    placements_count = placements.count
    success_rate = placements_count.positive? ? [ 64 + placements_count * 3, 94 ].min : 78
    freelance_profile = current_user.freelancer_profile
    {
      placements: placements_count,
      won_missions: [ placements_count + current_missions_scope.where(status: "in_progress").count, placements_count ].max,
      conversion_rate: success_rate,
      shortlist_delay: [ 6 - [ placements_count / 3, 3 ].min, 2 ].max,
      satisfaction: [ success_rate + 4, 98 ].min,
      rivyr_index: (((freelance_profile&.rivyr_score_current.to_i.nonzero? || 82).to_f) / 10).round(1),
      rating_chart: build_dashboard_rating_chart(freelance_profile, success_rate)
    }
  end

  def build_dashboard_rating_chart(freelance_profile, success_rate)
    snapshot =
      if defined?(FreelancerProfile) && FreelancerProfile.column_names.include?("performance_snapshot")
        freelance_profile&.performance_snapshot.presence
      end

    months = Array(snapshot&.dig("months")).presence || %w[Jan Feb Mar Apr May Jun Jul]
    current_values = Array(snapshot&.dig("current")).presence || generated_chart_series(months.size, freelance_profile, success_rate, variant: :current)
    previous_values = Array(snapshot&.dig("previous")).presence || generated_chart_series(months.size, freelance_profile, success_rate, variant: :previous)
    current_points = chart_points(current_values)
    previous_points = chart_points(previous_values)
    latest_value = current_values.last.to_f.round(1)
    previous_latest = previous_values.last.to_f.round(1)

    {
      months: months,
      current_values: current_values,
      previous_values: previous_values,
      current_points: current_points,
      previous_points: previous_points,
      current_path: svg_path_for(current_points),
      previous_path: svg_path_for(previous_points),
      highlight_point: current_points[[2, current_points.length - 1].min],
      latest_point: current_points.last,
      latest_value: latest_value,
      delta_value: (latest_value - previous_latest).round(1)
    }
  end

  def generated_chart_series(size, freelance_profile, success_rate, variant:)
    seed = freelance_profile&.id.to_i + freelance_profile&.rivyr_score_current.to_i
    base = [[(success_rate / 25.0), 2.6].max, 4.9].min

    size.times.map do |index|
      amplitude = variant == :current ? 0.38 : 0.52
      direction = variant == :current ? 0.12 : -0.04
      wave = ((seed + index * (variant == :current ? 3 : 5)) % 11) / 10.0
      value = base - amplitude + (index * direction) + wave - 0.3
      value.round(1).clamp(2.1, 4.9)
    end
  end

  def chart_points(values)
    width = 520.0
    height = 200.0
    padding_x = 12.0
    padding_y = 14.0
    max_value = 5.0
    min_value = 2.0
    step_x = values.length > 1 ? (width - padding_x * 2) / (values.length - 1) : 0

    values.each_with_index.map do |value, index|
      x = (padding_x + step_x * index).round(2)
      normalized = ((value.to_f - min_value) / (max_value - min_value)).clamp(0.0, 1.0)
      y = (height - padding_y - normalized * (height - padding_y * 2)).round(2)
      { x: x, y: y, value: value.to_f.round(1) }
    end
  end

  def svg_path_for(points)
    points.each_with_index.map { |point, index| "#{index.zero? ? 'M' : 'L'} #{point[:x]} #{point[:y]}" }.join(" ")
  end

  def match_reason_for(mission)
    specialty = mission.specialty&.name.to_s.downcase
    region = mission.region&.name
    "expertise #{specialty.presence || 'metier'} + couverture #{region.presence || 'nationale'}"
  end

  def distance_in_days(date)
    return 0 if date.blank?

    [ (Date.current - date.to_date).to_i, 0 ].max
  end
end
