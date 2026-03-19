class ClientPost < ApplicationRecord
  belongs_to :client
  has_many :client_post_reactions, dependent: :destroy
  has_many :client_post_comments, dependent: :destroy

  enum :post_type, { text_only: "text", photo: "photo", video: "video" }

  validates :body, presence: true, length: { maximum: 1000 }
  validates :title, length: { maximum: 120 }, allow_blank: true
  validates :media_url, length: { maximum: 500 }, allow_blank: true
  validates :post_type, presence: true

  scope :published, -> { where.not(published_at: nil).order(published_at: :desc) }
  scope :recent, -> { published.limit(3) }
end
