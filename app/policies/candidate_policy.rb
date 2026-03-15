class CandidatePolicy < ApplicationPolicy
  def index?
    admin? || freelance?
  end

  def show?
    admin? || freelance?
  end

  class Scope < Scope
    def resolve
      return scope.all if active_user? && (user.role_admin? || user.role_freelance?)

      scope.none
    end

    private

    def active_user?
      user.present? && user.status == "active"
    end
  end
end
