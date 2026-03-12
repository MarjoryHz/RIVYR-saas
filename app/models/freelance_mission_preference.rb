class FreelanceMissionPreference < ApplicationRecord
  belongs_to :freelancer_profile
  belongs_to :mission

  validates :mission_id, uniqueness: { scope: :freelancer_profile_id }
end
