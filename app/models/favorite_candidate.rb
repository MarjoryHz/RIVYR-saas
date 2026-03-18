class FavoriteCandidate < ApplicationRecord
  belongs_to :user
  belongs_to :candidate
  belongs_to :mission, optional: true

  validates :candidate_id, uniqueness: { scope: [:user_id, :mission_id] }
end
