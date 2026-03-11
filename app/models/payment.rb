class Payment < ApplicationRecord
  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed"
  }, prefix: true

  belongs_to :invoice
  belongs_to :commission

  validates :status, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :payment_type, length: { maximum: 100 }, allow_blank: true
  validates :reference, length: { maximum: 255 }, allow_blank: true

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    where("reference ILIKE :q OR payment_type ILIKE :q", q: "%#{q}%")
  }
end
