class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    admin?
  end

  def new?
    create?
  end

  def update?
    admin?
  end

  def edit?
    update?
  end

  def destroy?
    admin?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if active_user? && user.role_admin?

      scope.none
    end

    private

    def active_user?
      user.present? && user.status == "active"
    end
  end

  private

  def active_user?
    user.present? && user.status == "active"
  end

  def admin?
    active_user? && user.role_admin?
  end

  def freelance?
    active_user? && user.role_freelance?
  end

  def client?
    active_user? && user.role_client?
  end

  def candidate?
    active_user? && user.role_candidate?
  end
end
