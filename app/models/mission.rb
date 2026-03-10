class Mission < ApplicationRecord
  belongs_to :region, optional: true
  belongs_to :freelancer_profile
  belongs_to :client_contact
  has_one :client, through: :client_contact
  belongs_to :specialty, optional: true
  has_many :placements

  validates :title, presence: true
  validates :status, presence: true
  validates :reference, length: { maximum: 100 }, allow_blank: true
  validates :priority_level, length: { maximum: 50 }, allow_blank: true
end
