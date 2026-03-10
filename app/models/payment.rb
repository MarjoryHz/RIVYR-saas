class Payment < ApplicationRecord
  has_one :commission
  belongs_to :invoice

  validates :status, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :payment_type, length: { maximum: 100 }, allow_blank: true
  validates :reference, length: { maximum: 255 }, allow_blank: true
end
