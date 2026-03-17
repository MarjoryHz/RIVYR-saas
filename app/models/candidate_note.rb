class CandidateNote < ApplicationRecord
  belongs_to :candidate
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5000 }

  scope :recent, -> { order(created_at: :desc) }
end
