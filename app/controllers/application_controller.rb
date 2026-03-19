class ApplicationController < ActionController::Base
  include Pundit::Authorization
  helper_method :freelance_pending_validation_count, :freelance_unread_decision_count, :freelance_attention_count, :admin_pending_application_count

  before_action :authenticate_user!
  before_action :load_global_freelance_admin_updates
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def after_sign_in_path_for(resource)
    return dashboard_path if resource.respond_to?(:role_freelance?) && resource.role_freelance?
    return admin_mission_applications_path if resource.respond_to?(:role_admin?) && resource.role_admin?

    super
  end

  private

  def user_not_authorized
    redirect_back_or_to(root_path, alert: "Vous n'etes pas autorise a effectuer cette action.")
  end

  def paginate(scope, per_page: 20)
    total_count = scope.count
    total_pages = (total_count / per_page.to_f).ceil
    total_pages = 1 if total_pages.zero?

    page = params[:page].to_i
    page = 1 if page < 1
    page = total_pages if page > total_pages

    @page = page
    @per_page = per_page
    @total_pages = total_pages
    @total_count = total_count

    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def freelance_pending_validation_count
    return 0 unless current_user&.role_freelance?

    current_user.freelancer_profile&.freelance_mission_applications&.pending_validation&.count.to_i
  end

  def freelance_unread_decision_count
    return 0 unless current_user&.role_freelance?

    current_user.freelancer_profile&.freelance_mission_applications&.with_unread_freelance_decision&.count.to_i
  end

  def freelance_attention_count
    freelance_pending_validation_count + freelance_unread_decision_count
  end

  def admin_pending_application_count
    return 0 unless current_user&.role_admin?

    policy_scope(FreelanceMissionApplication).pending_validation.count + admin_unread_freelance_closure_count
  end

  def admin_unread_freelance_closure_count
    return 0 unless current_user&.role_admin?
    return 0 unless Mission.column_names.include?("closure_admin_read_at")

    policy_scope(Mission)
      .where(origin_type: "rivyr")
      .closed_by_freelance
      .where(closure_admin_read_at: nil)
      .count
  end

  def load_global_freelance_admin_updates
    @dashboard_admin_updates = []
    return unless current_user&.role_freelance?

    freelancer_profile = current_user.freelancer_profile
    return if freelancer_profile.blank?

    @dashboard_admin_updates = freelancer_profile.freelance_mission_applications
      .with_unread_freelance_decision
      .includes(:mission)
      .order(updated_at: :desc)
      .to_a
  end
end
