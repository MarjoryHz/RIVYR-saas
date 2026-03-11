class PlacementPolicy < ApplicationPolicy
  def index?
    admin? || freelance?
  end

  def show?
    admin? || own_freelance_placement?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.status == "active" && user.role_admin?
      return scope.joins(mission: :freelancer_profile).where(freelancer_profiles: { user_id: user.id }) if user&.status == "active" && user.role_freelance?

      scope.none
    end
  end

  private

  def own_freelance_placement?
    return false unless freelance?

    record.mission.freelancer_profile.user_id == user.id
  end
end
