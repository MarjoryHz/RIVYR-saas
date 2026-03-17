class Candidate < ApplicationRecord
  enum :status, {
    new: "new",
    qualified: "qualified",
    presented: "presented",
    interviewing: "interviewing",
    placed: "placed"
  }, prefix: true

  enum :availability, {
    immediate:      "immediate",
    one_month:      "one_month",
    three_months:   "three_months",
    six_months:     "six_months",
    other:          "other"
  }, prefix: true, allow_nil: true

  AVAILABILITY_LABELS = {
    "immediate"    => "Immédiate",
    "one_month"    => "Préavis d'1 mois",
    "three_months" => "Préavis de 3 mois",
    "six_months"   => "Préavis de 6 mois",
    "other"        => "Autre"
  }.freeze

  CONTRACT_LABELS = {
    "cdi"                   => "CDI",
    "cdd"                   => "CDD",
    "freelance"             => "Freelance",
    "interim"               => "Intérim",
    "management_transition" => "Management de transition"
  }.freeze

  SALARY_RANGES = [
    "< 30k€", "30 – 40k€", "40 – 50k€", "50 – 60k€",
    "60 – 75k€", "75 – 90k€", "90 – 110k€", "> 110k€"
  ].freeze

  has_many :placements, dependent: :nullify
  has_many :favorite_candidates, dependent: :destroy
  has_many :candidate_notes, dependent: :destroy
  has_many :work_experiences, -> { ordered }, dependent: :destroy
  has_many :educations,       -> { ordered }, dependent: :destroy
  belongs_to :user, optional: true

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :job_titles, :skills, length: { maximum: 20 }, allow_nil: true

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    where(
      "first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR source ILIKE :q",
      q: "%#{q}%"
    )
  }
end
