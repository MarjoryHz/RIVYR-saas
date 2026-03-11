class Placement < ApplicationRecord
  belongs_to :mission
  belongs_to :candidate

  has_one :invoice, dependent: :destroy
  has_one :commission, dependent: :destroy

  validates :status, presence: true
  validates :annual_salary_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :placement_fee_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
