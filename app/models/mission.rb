class Mission < ApplicationRecord
  enum :status, {
    open: "open",
    in_progress: "in_progress",
    closed: "closed"
  }, prefix: true

  belongs_to :region
  belongs_to :freelancer_profile
  belongs_to :client_contact
  belongs_to :specialty

  has_one :placement, dependent: :destroy

  validates :title, presence: true
  validates :reference, presence: true
  validates :status, presence: true
  validates :priority_level, length: { maximum: 50 }, allow_blank: true

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    where(
      "title ILIKE :q OR reference ILIKE :q OR mission_type ILIKE :q OR origin_type ILIKE :q",
      q: "%#{q}%"
    )
  }
end
