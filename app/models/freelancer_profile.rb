class FreelancerProfile < ApplicationRecord
  belongs_to :region
  belongs_to :user
  belongs_to :specialty
end
