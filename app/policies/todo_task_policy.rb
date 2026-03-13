class TodoTaskPolicy < ApplicationPolicy
  def create?
    freelance?
  end

  def update?
    freelance? && record.user_id == user.id
  end

  def destroy?
    update?
  end
end
