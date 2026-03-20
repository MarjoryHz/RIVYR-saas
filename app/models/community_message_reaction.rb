class CommunityMessageReaction < ApplicationRecord
  belongs_to :community_message
  belongs_to :user

  validates :emoji, presence: true
  validates :emoji, uniqueness: { scope: [:community_message_id, :user_id] }
end
