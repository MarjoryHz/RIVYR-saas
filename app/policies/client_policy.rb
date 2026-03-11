class ClientPolicy < ApplicationPolicy
  def show?
    admin?
  end
end
