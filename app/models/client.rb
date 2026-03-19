class Client < ApplicationRecord
  has_many :client_contacts, dependent: :destroy
  has_many :missions, through: :client_contacts
  has_many :client_highlights, dependent: :destroy
  has_many :client_values, dependent: :destroy
  has_many :client_posts, dependent: :destroy
  has_many :client_subscriptions, dependent: :destroy
  has_many :subscribers, through: :client_subscriptions, source: :user

  validates :legal_name, presence: true
  validates :sector, length: { maximum: 255 }, allow_blank: true
  validates :website_url, length: { maximum: 255 }, allow_blank: true
  validates :company_size, length: { maximum: 100 }, allow_blank: true
  validates :ambiance, length: { maximum: 400 }, allow_blank: true

  scope :search, lambda { |q|
    return all if q.blank?

    where(
      "legal_name ILIKE :q OR brand_name ILIKE :q OR sector ILIKE :q OR location ILIKE :q",
      q: "%#{q}%"
    )
  }
end
