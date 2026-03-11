class Commission < ApplicationRecord
  enum :status, {
    eligible: "eligible",
    paid: "paid",
    canceled: "canceled"
  }, prefix: true

  belongs_to :placement
  has_many :payments, dependent: :destroy

  validates :commission_rule, presence: true
  validates :status, presence: true
  validates :gross_amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rivyr_share_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :freelancer_share_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    where("commission_rule ILIKE :q", q: "%#{q}%")
  }
end
