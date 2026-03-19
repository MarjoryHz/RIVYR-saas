class ClientPostComment < ApplicationRecord
  belongs_to :client_post
  belongs_to :user
  has_many :client_post_comment_reactions, dependent: :destroy

  validates :body, presence: true, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :asc) }
end
