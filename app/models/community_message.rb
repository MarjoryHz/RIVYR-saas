class CommunityMessage < ApplicationRecord
  belongs_to :community_channel
  belongs_to :user
  belongs_to :parent, class_name: "CommunityMessage", optional: true

  has_many :replies, class_name: "CommunityMessage", foreign_key: :parent_id, dependent: :destroy
  has_many :community_message_reactions, dependent: :destroy

  scope :top_level, -> { where(parent_id: nil) }
  scope :recent_first, -> { order(created_at: :desc) }
end
