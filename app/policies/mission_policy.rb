class MissionPolicy < ApplicationPolicy
  def index?
    admin? || freelance? || client? || candidate?
  end

  def my_missions?
    index?
  end

  def show?
    admin? || mission_owned_by_freelance? || mission_owned_by_client? || candidate?
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
    !candidate?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.status == "active" && user.role_admin?

      return scope.joins(:freelancer_profile).where(freelancer_profiles: { user_id: user.id }) if user&.status == "active" && user.role_freelance?
      return scope.joins(:client_contact).where(client_contacts: { user_id: user.id }) if user&.status == "active" && user.role_client?
      return scope.all if user&.status == "active" && user.role_candidate?

      scope.none
    end
  end

  private

  def mission_owned_by_freelance?
    freelance? && record.freelancer_profile&.user_id == user.id
  end

  def mission_owned_by_client?
    client? && record.client_contact&.user_id == user.id
  end
end
