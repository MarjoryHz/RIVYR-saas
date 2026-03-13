class TodoCategoryPolicy < ApplicationPolicy
  def create?
    freelance?
  end

  def update?
    freelance? && record.user_id == user.id
  end

  def destroy?
    update? && !record.system?
  end
end
