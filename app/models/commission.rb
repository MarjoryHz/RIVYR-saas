class Commission < ApplicationRecord
  belongs_to :placement
  has_many :payments, dependent: :destroy

  validates :commission_rule, presence: true
  validates :status, presence: true
  validates :gross_amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rivyr_share_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :freelancer_share_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
