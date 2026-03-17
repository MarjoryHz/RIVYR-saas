class FavoriteCandidate < ApplicationRecord
  belongs_to :user
  belongs_to :candidate

  validates :candidate_id, uniqueness: { scope: :user_id }
end
