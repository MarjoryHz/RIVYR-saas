class FreelanceFinancePolicy < ApplicationPolicy
  def show?
    freelance?
  end

  def create_client_invoice?
    freelance?
  end

  def create_freelancer_invoice?
    freelance?
  end

  def create_payout_request?
    freelance?
  end
end
