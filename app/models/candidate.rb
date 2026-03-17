class Candidate < ApplicationRecord
  enum :status, {
    new: "new",
    qualified: "qualified",
    presented: "presented",
    interviewing: "interviewing",
    placed: "placed"
  }, prefix: true

  has_many :placements, dependent: :nullify
  has_many :favorite_candidates, dependent: :destroy
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
