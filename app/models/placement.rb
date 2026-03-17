class Placement < ApplicationRecord
  enum :status, {
    validated: "validated",
    invoiced: "invoiced",
    paid: "paid",
    pending_guarantee: "pending_guarantee"
  }, prefix: true

  enum :workflow_status, {
    in_progress: "in_progress",
    validated: "validated",
    refused: "refused"
  }, prefix: :workflow

  belongs_to :mission
  belongs_to :candidate
  belongs_to :freelancer_profile, optional: true
  belongs_to :admin_reviewer, class_name: "User", foreign_key: :admin_reviewed_by_id, optional: true

  has_many :invoices, dependent: :destroy
  has_one :client_invoice, -> { where(invoice_type: "client") }, class_name: "Invoice"
  has_one :freelancer_invoice, -> { where(invoice_type: "freelancer") }, class_name: "Invoice"
  has_one :commission, dependent: :destroy

  validates :status, presence: true
  validates :workflow_status, presence: true
  validates :annual_salary_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :placement_fee_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :package_summary, length: { maximum: 255 }, allow_blank: true
  validates :admin_review_note, length: { maximum: 2_000 }, allow_blank: true

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :with_workflow_status, ->(value) { value.present? ? where(workflow_status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    joins(:mission, :candidate).where(
      "missions.reference ILIKE :q OR missions.title ILIKE :q OR candidates.first_name ILIKE :q OR candidates.last_name ILIKE :q",
      q: "%#{q}%"
    )
  }

  before_validation :sync_freelancer_profile_from_mission

  def ready_for_admin_review?
    annual_salary_cents.to_i.positive? && package_summary.present? && !client_offer_compliant.nil? && candidate_accepted == true
  end

  def sync_commission!
    gross_amount_cents = (annual_salary_cents.to_i * 0.20).round
    freelancer_share_cents = (gross_amount_cents * 0.60).round
    rivyr_share_cents = gross_amount_cents - freelancer_share_cents

    commission_record = commission || build_commission
    commission_record.assign_attributes(
      commission_rule: "20% honoraires / 60% freelance / 40% Rivyr",
      status: "eligible",
      gross_amount_cents: gross_amount_cents,
      freelancer_share_cents: freelancer_share_cents,
      rivyr_share_cents: rivyr_share_cents,
      client_payment_required: true,
      eligible_for_invoicing_at: Date.current
    )
    commission_record.save!

    update!(placement_fee_cents: gross_amount_cents) if placement_fee_cents != gross_amount_cents
  end

  private

  def sync_freelancer_profile_from_mission
    self.freelancer_profile_id ||= mission&.freelancer_profile_id
  end
end
