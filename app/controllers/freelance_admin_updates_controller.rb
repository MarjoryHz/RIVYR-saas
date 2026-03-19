class FreelanceAdminUpdatesController < ApplicationController
  def acknowledge
    return head :forbidden unless current_user&.role_freelance?
    return head :ok unless FreelanceMissionApplication.supports_freelancer_notification_tracking?

    application_ids = Array(params[:application_ids]).filter_map do |value|
      Integer(value, exception: false)
    end

    if application_ids.any?
      current_user.freelancer_profile&.freelance_mission_applications
        &.where(id: application_ids)
        &.update_all(freelancer_notified_at: Time.current)
    end

    head :ok
  end
end
