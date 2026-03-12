class MissionPolicy < ApplicationPolicy
  def index?
    admin? || freelance? || client? || candidate?
  end

  def my_missions?
    index?
  end

  def pending_missions?
    index?
  end

  def library?
    index?
  end

  def apply?
    freelance?
  end

  def show?
    admin? || mission_owned_by_freelance? || mission_owned_by_client? || mission_applied_by_freelance? || candidate? || freelance_can_view_open_library_mission?
  end

  def create?
    return true if admin?
    return user.freelancer_profile.present? if freelance?
    return user.client_contact.present? if client?

    false
  end

  def update?
    admin? || mission_owned_by_freelance? || mission_owned_by_client?
  end

  def destroy?
    update?
  end

  def view_client_identity?
    return true if admin? || client?
    return false unless record.is_a?(Mission)

    mission_owned_by_freelance?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.status == "active" && user.role_admin?

      return scope.joins(:freelancer_profile).where(freelancer_profiles: { user_id: user.id }) if user&.status == "active" && user.role_freelance?
      return scope.joins(:client_contact).where(client_contacts: { user_id: user.id }) if user&.status == "active" && user.role_client?
      return scope.all if user&.status == "active" && user.role_candidate?

      scope.none
    end

    def resolve_for_library
      return scope.none unless user&.status == "active" && user.role_freelance?

      scope
        .joins(freelancer_profile: :user)
        .where(status: "open")
        .where(users: { role: "admin" })
    end
  end

  private

  def mission_owned_by_freelance?
    freelance? && record.freelancer_profile&.user_id == user.id
  end

  def mission_owned_by_client?
    client? && record.client_contact&.user_id == user.id
  end

  def mission_applied_by_freelance?
    freelance? && user.freelancer_profile&.freelance_mission_applications&.exists?(mission_id: record.id)
  end

  def freelance_can_view_open_library_mission?
    freelance? && record.status == "open"
  end
end
