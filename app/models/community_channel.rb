class CommunityChannel < ApplicationRecord
  has_many :community_messages, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :ordered, -> { order(:position) }
end
