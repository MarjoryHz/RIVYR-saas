class Mission < ApplicationRecord
  enum :status, {
    draft: "draft",
    open: "open",
    in_progress: "in_progress",
    closed: "closed"
  }, prefix: true

  belongs_to :region, optional: true
  belongs_to :freelancer_profile
  belongs_to :client_contact, optional: true
  belongs_to :specialty, optional: true

  has_one :placement, dependent: :destroy
  has_many :freelance_mission_preferences, dependent: :destroy
  has_many :freelance_mission_applications, dependent: :destroy
  has_many :favorite_missions, dependent: :destroy
  has_many :favorited_by_users, through: :favorite_missions, source: :user

  validates :title, presence: true, unless: :status_draft?
  validates :reference, presence: true
  validates :status, presence: true
  validates :closure_reason, length: { maximum: 100 }, allow_blank: true
  validates :closure_note, length: { maximum: 3_000 }, allow_blank: true
  validates :priority_level, length: { maximum: 50 }, allow_blank: true
  validates :client_contact, :region, :specialty, presence: true, unless: :status_draft?

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :closed_by_freelance, -> { where.not(closed_by_freelancer_at: nil) }
  scope :search, lambda { |q|
    return all if q.blank?

    where(
      "title ILIKE :q OR reference ILIKE :q OR mission_type ILIKE :q OR origin_type ILIKE :q",
      q: "%#{q}%"
    )
  }
end
