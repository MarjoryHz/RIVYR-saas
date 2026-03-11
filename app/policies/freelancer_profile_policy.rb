class FreelancerProfilePolicy < ApplicationPolicy
  def index?
    admin? || freelance? || client? || candidate?
  end

  def show?
    index?
  end

  def create?
    admin?
  end

  def update?
    admin? || own_profile?
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.status == "active" && (user.role_admin? || user.role_freelance? || user.role_client? || user.role_candidate?)

      scope.none
    end
  end

  private

  def own_profile?
    freelance? && record.user_id == user.id
  end
end
