class ClientPostCommentReaction < ApplicationRecord
  belongs_to :client_post_comment
  belongs_to :user

  validates :emoji, presence: true, inclusion: { in: %w[heart] }
  validates :user_id, uniqueness: { scope: :client_post_comment_id }
end
