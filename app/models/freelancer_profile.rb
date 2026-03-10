class FreelancerProfile < ApplicationRecord
  belongs_to :region, optional: true
  belongs_to :user
  belongs_to :specialty

  has_many :missions, dependent: :nullify

  validates :bio, length: { maximum: 2000 }, allow_blank: true
  validates :linkedin_url, length: { maximum: 255 }, allow_blank: true
  validates :website_url, length: { maximum: 255 }, allow_blank: true
  validates :rivyr_score_current, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
