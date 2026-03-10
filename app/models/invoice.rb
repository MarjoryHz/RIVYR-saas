class Invoice < ApplicationRecord
  belongs_to :placement

  has_one :payment, dependent: :nullify

  validates :number, presence: true, uniqueness: true
  validates :invoice_type, presence: true
  validates :status, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
