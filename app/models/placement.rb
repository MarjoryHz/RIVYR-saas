class Placement < ApplicationRecord
  enum :status, {
    validated: "validated",
    invoiced: "invoiced",
    paid: "paid",
    pending_guarantee: "pending_guarantee"
  }, prefix: true

  belongs_to :mission
  belongs_to :candidate

  has_many :invoices, dependent: :destroy
  has_one :client_invoice, -> { where(invoice_type: "client") }, class_name: "Invoice"
  has_one :freelancer_invoice, -> { where(invoice_type: "freelancer") }, class_name: "Invoice"
  has_one :commission, dependent: :destroy

  validates :status, presence: true
  validates :annual_salary_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :placement_fee_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    joins(:mission, :candidate).where(
      "missions.reference ILIKE :q OR missions.title ILIKE :q OR candidates.first_name ILIKE :q OR candidates.last_name ILIKE :q",
      q: "%#{q}%"
    )
  }
end
