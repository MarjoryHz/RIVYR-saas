class FreelancerProfile < ApplicationRecord
  FREELANCE_LEGAL_STATUSES = {
    "autoentrepreneur" => "Auto-entrepreneur",
    "ei" => "Entreprise individuelle",
    "eurl" => "EURL",
    "sarl" => "SARL",
    "sasu" => "SASU",
    "sas" => "SAS",
    "portage_salarial" => "Portage salarial",
    "autre" => "Autre"
  }.freeze

  enum :operational_status, {
    onboarded: "onboarded",
    active: "active",
    paused: "paused"
  }, prefix: true

  enum :availability_status, {
    available: "available",
    partially_available: "partially_available",
    busy: "busy"
  }, prefix: true

  belongs_to :region, optional: true
  belongs_to :user
  belongs_to :specialty

  has_many :missions, dependent: :nullify
  has_many :freelance_mission_preferences, dependent: :destroy
  has_many :freelance_mission_applications, dependent: :destroy

  before_validation :normalize_monthly_revenue_targets_eur

  validates :bio, length: { maximum: 2000 }, allow_blank: true
  validates :linkedin_url, length: { maximum: 255 }, allow_blank: true
  validates :website_url, length: { maximum: 255 }, allow_blank: true
  validates :primary_bank_account_label, :secondary_bank_account_label, length: { maximum: 255 }, allow_blank: true
  validates :primary_bank_iban, :secondary_bank_iban, length: { maximum: 34 }, allow_blank: true
  validates :primary_bank_bic, :secondary_bank_bic, length: { maximum: 11 }, allow_blank: true
  validates :rivyr_score_current, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :annual_revenue_target_eur, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :freelance_legal_status, inclusion: { in: FREELANCE_LEGAL_STATUSES.keys }, allow_blank: true
  validate :monthly_revenue_targets_are_valid

  scope :with_operational_status, ->(value) { value.present? ? where(operational_status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    joins(:user).where(
      "users.first_name ILIKE :q OR users.last_name ILIKE :q OR users.email ILIKE :q",
      q: "%#{q}%"
    )
  }

  def monthly_revenue_target_for(date)
    month_key = format("%02d", date.month)
    target = monthly_revenue_targets_eur.to_h[month_key].to_i
    return target if target.positive?

    annual_revenue_target_eur.to_i.positive? ? (annual_revenue_target_eur.to_f / 12).round : 0
  end

  def freelance_legal_status_label
    FREELANCE_LEGAL_STATUSES[freelance_legal_status.to_s].presence || "Non renseigne"
  end

  def bank_accounts
    [
      {
        label: primary_bank_account_label.presence || (primary_bank_iban.present? || primary_bank_bic.present? ? "Compte bancaire 1" : nil),
        iban: primary_bank_iban,
        bic: primary_bank_bic
      },
      {
        label: secondary_bank_account_label.presence || (secondary_bank_iban.present? || secondary_bank_bic.present? ? "Compte bancaire 2" : nil),
        iban: secondary_bank_iban,
        bic: secondary_bank_bic
      }
    ].select { |account| account[:label].present? || account[:iban].present? || account[:bic].present? }
  end

  private

  def normalize_monthly_revenue_targets_eur
    self.monthly_revenue_targets_eur =
      monthly_revenue_targets_eur.to_h.each_with_object({}) do |(key, value), hash|
        month_number = key.to_s[/\d+/].to_i
        next unless month_number.between?(1, 12)

        normalized_value = value.to_s.gsub(/[^\d]/, "")
        hash[format("%02d", month_number)] = normalized_value.present? ? normalized_value.to_i : 0
      end
  end

  def monthly_revenue_targets_are_valid
    monthly_revenue_targets_eur.to_h.each do |key, value|
      month_number = key.to_s[/\d+/].to_i
      unless month_number.between?(1, 12)
        errors.add(:monthly_revenue_targets_eur, "contient un mois invalide")
        next
      end

      numeric_value = value.to_i
      errors.add(:monthly_revenue_targets_eur, "doit contenir des montants positifs") if numeric_value.negative?
    end
  end
end
