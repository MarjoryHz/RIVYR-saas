class Mission < ApplicationRecord
  belongs_to :region
  belongs_to :freelancer_profile
  belongs_to :client_contact
  belongs_to :specialty

  has_one :placement, dependent: :destroy

  validates :title, presence: true
  validates :reference, presence: true
  validates :status, presence: true
  validates :priority_level, length: { maximum: 50 }, allow_blank: true
end
