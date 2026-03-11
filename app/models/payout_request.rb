class PayoutRequest < ApplicationRecord
  enum :status, {
    pending: "pending",
    approved: "approved",
    paid: "paid",
    rejected: "rejected"
  }, prefix: true

  belongs_to :user
  belongs_to :invoice

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :billing_number, presence: true
  validates :requested_at, presence: true
  validates :status, presence: true
end
