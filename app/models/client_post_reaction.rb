class ClientPostReaction < ApplicationRecord
  belongs_to :client_post
  belongs_to :user

  validates :emoji, presence: true
  validates :user_id, uniqueness: { scope: :client_post_id }
end
