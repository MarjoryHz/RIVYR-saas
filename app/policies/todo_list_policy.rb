class TodoListPolicy < ApplicationPolicy
  def show?
    freelance?
  end
end
