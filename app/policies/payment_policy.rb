class PaymentPolicy < ApplicationPolicy
  def index?
    admin? || freelance?
  end

  def show?
    admin? || own_freelance_payment?
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
      return scope.joins(commission: { placement: { mission: :freelancer_profile } }).where(freelancer_profiles: { user_id: user.id }) if user&.status == "active" && user.role_freelance?

      scope.none
    end
  end

  private

  def own_freelance_payment?
    return false unless freelance?

    record.commission.placement.mission.freelancer_profile.user_id == user.id
  end
end
