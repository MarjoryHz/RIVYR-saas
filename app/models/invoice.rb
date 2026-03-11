class Invoice < ApplicationRecord
  enum :status, {
    issued: "issued",
    paid: "paid",
    canceled: "canceled"
  }, prefix: true

  belongs_to :placement

  has_one :payment, dependent: :nullify

  validates :number, presence: true, uniqueness: true
  validates :invoice_type, presence: true
  validates :status, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    where("number ILIKE :q OR invoice_type ILIKE :q", q: "%#{q}%")
  }
end
