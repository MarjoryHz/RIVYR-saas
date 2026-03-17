class FreelanceMissionApplicationPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def accept?
    admin?
  end

  def reject?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.status == "active" && user.role_admin?

      scope.none
    end
  end
end
