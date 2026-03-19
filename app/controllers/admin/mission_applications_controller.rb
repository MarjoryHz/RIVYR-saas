module Admin
  class MissionApplicationsController < ApplicationController
    before_action :ensure_admin!
    before_action :set_application, only: [ :accept, :reject ]

    def index
      authorize FreelanceMissionApplication

      pending_applications = policy_scope(FreelanceMissionApplication)
        .pending_validation
        .includes(
          :mission,
          freelancer_profile: [ :region, :specialty, :user ],
          mission: [ :region, :specialty, { client_contact: :client } ]
        )
        .joins(mission: { freelancer_profile: :user })
        .where(users: { role: "admin" })
        .order("missions.opened_at DESC NULLS LAST, freelance_mission_applications.created_at ASC")

      @mission_application_groups = pending_applications.group_by(&:mission).map do |mission, applications|
        {
          mission: mission,
          applications: applications
            .map { |application| build_application_review_row(application) }
            .sort_by { |row| -row[:compatibility][:total] }
        }
      end
      @pending_applications_count = pending_applications.count

      @closed_missions_alerts = load_closed_missions_alerts
      mark_closed_missions_alerts_as_read(@closed_missions_alerts)
    end

    def accept
      authorize @application, :accept?
      applications_to_broadcast = []

      ActiveRecord::Base.transaction do
        mission = @application.mission

        mission.update!(
          freelancer_profile: @application.freelancer_profile,
          started_at: mission.started_at || Date.current,
          status: mission.status.presence || "open"
        )

        @application.update!(
          review_update_attributes(
            status: "accepted",
            client_validated_at: Time.current,
            review_reason: nil,
            reviewed_by: current_user,
            freelancer_notified_at: nil
          )
        )
        applications_to_broadcast << @application

        mission.freelance_mission_applications
          .where.not(id: @application.id)
          .pending_validation
          .find_each do |application|
            application.update!(
              review_update_attributes(
                status: "rejected",
                client_rejected_at: Time.current,
                review_reason: "Mission attribuée à un autre freelance.",
                reviewed_by: current_user,
                freelancer_notified_at: nil
              )
            )
            applications_to_broadcast << application
          end
      end

      applications_to_broadcast.each { |application| broadcast_freelance_decision_update(application) }

      redirect_to admin_mission_applications_path, notice: "Le freelance a été affecté à la mission."
    end

    def reject
      authorize @application, :reject?

      reason = params.dig(:freelance_mission_application, :review_reason).to_s.strip
      reason = "Candidature non retenue par RIVYR." if reason.blank?

      @application.update!(
        review_update_attributes(
          status: "rejected",
          client_rejected_at: Time.current,
          review_reason: reason,
          reviewed_by: current_user,
          freelancer_notified_at: nil
        )
      )
      broadcast_freelance_decision_update(@application)

      redirect_to admin_mission_applications_path, notice: "La candidature a été refusée."
    end

    private

    def ensure_admin!
      return if current_user&.role_admin?

      redirect_to root_path, alert: "Vous n'etes pas autorise a effectuer cette action."
    end

    def set_application
      @application = policy_scope(FreelanceMissionApplication)
        .includes(:mission, freelancer_profile: [ :region, :specialty, :user ])
        .find(params[:id])
    end

    def build_application_review_row(application)
      compatibility = compatibility_for(application.mission, application.freelancer_profile)

      {
        application: application,
        freelancer_profile: application.freelancer_profile,
        freelancer_user: application.freelancer_profile.user,
        compatibility: compatibility
      }
    end

    def compatibility_for(mission, freelance_profile)
      specialty_points = mission.specialty_id == freelance_profile.specialty_id ? 35 : 0
      region_points = mission.region_id == freelance_profile.region_id ? 20 : 0
      recruited_points = recruited_specialty_ids_for_year(freelance_profile).include?(mission.specialty_id) ? 10 : 0
      priority_points = priority_bonus(mission.priority_level)
      recency_points = recency_bonus(mission.opened_at)
      rivyr_points = mission.origin_type == "rivyr" ? 5 : 0
      total = (specialty_points + region_points + recruited_points + priority_points + recency_points + rivyr_points).clamp(0, 100)

      {
        total: total,
        specialty: specialty_points,
        region: region_points,
        recruited_same_type: recruited_points,
        priority: priority_points,
        recency: recency_points,
        rivyr_origin: rivyr_points
      }
    end

    def recruited_specialty_ids_for_year(freelance_profile)
      Placement
        .joins(:mission)
        .where(missions: { freelancer_profile_id: freelance_profile.id })
        .where(hired_at: Date.current.beginning_of_year..Date.current.end_of_year)
        .distinct
        .pluck("missions.specialty_id")
    end

    def priority_bonus(priority_level)
      case priority_level.to_s.downcase
      when "critical" then 12
      when "high" then 8
      when "medium" then 4
      else 0
      end
    end

    def recency_bonus(opened_at)
      return 0 if opened_at.blank?

      days = (Date.current - opened_at).to_i
      return 10 if days <= 7
      return 6 if days <= 30
      return 3 if days <= 60

      0
    end

    def review_update_attributes(attributes)
      filtered = attributes.slice(:status, :client_validated_at, :client_rejected_at)
      filtered[:review_reason] = attributes[:review_reason] if FreelanceMissionApplication.supports_review_reason?
      filtered[:reviewed_by] = attributes[:reviewed_by] if FreelanceMissionApplication.supports_review_tracking?
      if FreelanceMissionApplication.supports_freelancer_notification_tracking?
        filtered[:freelancer_notified_at] = attributes[:freelancer_notified_at]
      end
      filtered
    end

    def load_closed_missions_alerts
      return [] unless Mission.column_names.include?("closure_admin_read_at")

      policy_scope(Mission)
        .includes(:region, :client_contact, freelancer_profile: :user)
        .where(origin_type: "rivyr")
        .closed_by_freelance
        .where(closure_admin_read_at: nil)
        .order(closed_by_freelancer_at: :desc)
        .to_a
    end

    def mark_closed_missions_alerts_as_read(missions)
      return if missions.empty?
      return unless Mission.column_names.include?("closure_admin_read_at")

      Mission.where(id: missions.map(&:id)).update_all(closure_admin_read_at: Time.current)
    end

    def broadcast_freelance_decision_update(application)
      freelancer_user = application.freelancer_profile&.user
      return unless freelancer_user&.role_freelance?

      Turbo::StreamsChannel.broadcast_replace_to(
        "freelance_admin_updates:#{freelancer_user.id}",
        target: "global_admin_updates_modal_host",
        partial: "missions/admin_updates_modal",
        locals: {
          admin_updates: [ application ],
          container_id: "global_admin_updates_modal_host"
        }
      )
    end
  end
end
