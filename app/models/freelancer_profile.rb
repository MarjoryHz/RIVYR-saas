class FreelancerProfile < ApplicationRecord
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

  validates :bio, length: { maximum: 2000 }, allow_blank: true
  validates :linkedin_url, length: { maximum: 255 }, allow_blank: true
  validates :website_url, length: { maximum: 255 }, allow_blank: true
  validates :rivyr_score_current, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :with_operational_status, ->(value) { value.present? ? where(operational_status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    joins(:user).where(
      "users.first_name ILIKE :q OR users.last_name ILIKE :q OR users.email ILIKE :q",
      q: "%#{q}%"
    )
  }
end
