class ClientContact < ApplicationRecord
  belongs_to :client
  belongs_to :user, optional: true
  has_many :missions, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :job_title, length: { maximum: 255 }, allow_blank: true
  validates :avatar, length: { maximum: 255 }, allow_blank: true

  scope :search, lambda { |q|
    return all if q.blank?

    where(
      "first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR job_title ILIKE :q",
      q: "%#{q}%"
    )
  }
end
