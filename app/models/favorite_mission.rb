class FavoriteMission < ApplicationRecord
  belongs_to :user
  belongs_to :mission

  validates :mission_id, uniqueness: { scope: :user_id }
end
