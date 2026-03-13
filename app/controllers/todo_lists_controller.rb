class TodoListsController < ApplicationController
  def show
    authorize :todo_list, :show?

    ensure_default_categories!

    profile = current_user.freelancer_profile

    assigned_scope = Mission
      .includes(:client_contact, :region, :placement)
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })

    current_missions_scope = assigned_scope.where(status: %w[open in_progress])
    urgent_preferences = if profile.present?
      profile.freelance_mission_preferences.where(urgent: true, mission_id: current_missions_scope.select(:id))
    else
      FreelanceMissionPreference.none
    end

    pending_applications = if profile.present?
      profile.freelance_mission_applications.pending_validation.includes(:mission)
    else
      FreelanceMissionApplication.none
    end

    placements_scope = Placement
      .includes(:mission, :client_invoice, :freelancer_invoice)
      .joins(mission: :freelancer_profile)
      .where(freelancer_profiles: { user_id: current_user.id })

    client_invoices_to_follow = placements_scope.select { |placement| placement.client_invoice&.status_issued? }
    freelancer_invoices_to_issue = placements_scope.select do |placement|
      placement.client_invoice&.status_paid? && placement.freelancer_invoice.blank?
    end
    missions_pending_signature = current_missions_scope.where(contract_signed: [ false, nil ])
    stalled_missions = current_missions_scope.select do |mission|
      started_on = mission.started_at || mission.opened_at || mission.created_at.to_date
      next false if started_on.blank?

      open_days = (Date.current - started_on).to_i
      open_days > 45
    end

    @todo_kpis = {
      urgent_count: urgent_preferences.count,
      pending_validation_count: pending_applications.count,
      active_missions_count: current_missions_scope.count,
      finance_actions_count: client_invoices_to_follow.count + freelancer_invoices_to_issue.count,
      tasks_count: current_user.todo_tasks.count
    }

    @todo_sections = [
      {
        title: "Priorites du jour",
        tone: "bg-[#fff2f7] border-[#f6c7d9]",
        items: [
          {
            title: "Traiter vos missions urgentes",
            detail: "#{urgent_preferences.count} mission#{'s' if urgent_preferences.count > 1} marquee#{'s' if urgent_preferences.count > 1} comme urgente#{'s' if urgent_preferences.count > 1}.",
            status: urgent_preferences.any? ? "A faire" : "Rien d'urgent",
            action_label: "Voir mes missions",
            action_path: my_missions_missions_path
          },
          {
            title: "Relancer vos validations en attente",
            detail: "#{pending_applications.count} mission#{'s' if pending_applications.count > 1} attend#{pending_applications.count > 1 ? 'ent' : ''} encore une action.",
            status: pending_applications.any? ? "En attente" : "A jour",
            action_label: "Voir les validations",
            action_path: pending_missions_missions_path
          }
        ]
      },
      {
        title: "Suivi business",
        tone: "bg-[#fff8f5] border-[#f3d5ca]",
        items: [
          {
            title: "Suivre vos missions actives",
            detail: "#{current_missions_scope.count} mission#{'s' if current_missions_scope.count > 1} en cours a faire avancer.",
            status: current_missions_scope.any? ? "En cours" : "Vide",
            action_label: "Ouvrir mes missions",
            action_path: my_missions_missions_path
          },
          {
            title: "Piloter vos actions finance",
            detail: "#{client_invoices_to_follow.count} facture#{'s' if client_invoices_to_follow.count > 1} client a suivre, #{freelancer_invoices_to_issue.count} facture#{'s' if freelancer_invoices_to_issue.count > 1} freelance a emettre.",
            status: (client_invoices_to_follow.any? || freelancer_invoices_to_issue.any?) ? "Action requise" : "Sous controle",
            action_label: "Ouvrir finances",
            action_path: freelance_finance_path
          }
        ]
      }
    ]

    @todo_categories = current_user.todo_categories.includes(:todo_tasks).ordered
    @task_query = params[:q].to_s.strip
    @task_status_filter = params[:status].to_s
    @task_priority_filter = params[:priority].to_s
    @task_category_filter = params[:category_id].to_s
    @todo_task = if params[:edit_task].present?
      current_user.todo_tasks.find(params[:edit_task])
    else
      current_user.todo_tasks.new(status: "todo", priority: "medium")
    end
    @category_to_edit = if params[:edit_category].present?
      current_user.todo_categories.find(params[:edit_category])
    else
      current_user.todo_categories.new
    end
    filtered_scope = current_user.todo_tasks.includes(:todo_category)
    if @task_query.present?
      filtered_scope = filtered_scope.where(
        "todo_tasks.title ILIKE :query OR todo_tasks.description ILIKE :query",
        query: "%#{@task_query}%"
      )
    end
    filtered_scope = filtered_scope.where(status: @task_status_filter) if @task_status_filter.present?
    filtered_scope = filtered_scope.where(priority: @task_priority_filter) if @task_priority_filter.present?
    filtered_scope = filtered_scope.where(todo_category_id: @task_category_filter) if @task_category_filter.present?

    ordered_tasks = filtered_scope.ordered.to_a
    urgent_tasks, regular_tasks = ordered_tasks.partition { |task| task.priority_high? && !task.status_done? }

    @todo_tasks_groups = {
      "urgent" => urgent_tasks,
      "todo" => regular_tasks.select(&:status_todo?),
      "in_progress" => regular_tasks.select(&:status_in_progress?),
      "done" => regular_tasks.select(&:status_done?)
    }

    @recommended_actions = [
      {
        title: "Contrats a faire signer",
        detail: "#{missions_pending_signature.count} mission#{'s' if missions_pending_signature.count > 1} n'ont pas encore de contrat signe.",
        status: missions_pending_signature.any? ? "Signature requise" : "A jour",
        icon: "fa-signature",
        action_label: "Voir mes missions",
        action_path: my_missions_missions_path,
        highlight: missions_pending_signature.any?
      },
      {
        title: "Missions a relancer",
        detail: "#{stalled_missions.count} mission#{'s' if stalled_missions.count > 1} semble#{'nt' if stalled_missions.count > 1} ralentir et demande#{stalled_missions.count > 1 ? 'nt' : ''} une action.",
        status: stalled_missions.any? ? "Relance recommandee" : "RAS",
        icon: "fa-bolt",
        action_label: "Voir mes missions",
        action_path: my_missions_missions_path,
        highlight: stalled_missions.any?
      },
      {
        title: "Validations client a suivre",
        detail: "#{pending_applications.count} validation#{'s' if pending_applications.count > 1} est#{pending_applications.count > 1 ? '' : ''} encore en attente de retour.",
        status: pending_applications.any? ? "En attente" : "Sous controle",
        icon: "fa-user-clock",
        action_label: "Voir les validations",
        action_path: pending_missions_missions_path,
        highlight: pending_applications.any?
      }
    ]
  end

  private

  def ensure_default_categories!
    existing_names = current_user.todo_categories.pluck(:name)

    TodoCategory::DEFAULT_NAMES.each do |name|
      next if existing_names.include?(name)

      current_user.todo_categories.create!(name: name, system: true)
    end
  end
end
