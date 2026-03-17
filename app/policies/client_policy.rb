class ClientPolicy < ApplicationPolicy
  def show?
    admin? || client_visible_to_assigned_freelance?
  end

  private

  def client_visible_to_assigned_freelance?
    return false unless freelance? && user.freelancer_profile.present?

    record
      .missions
      .joins(:freelancer_profile)
      .where(freelancer_profiles: { user_id: user.id })
      .exists?
  end
end
