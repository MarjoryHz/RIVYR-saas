class Mission < ApplicationRecord
  belongs_to :region
  belongs_to :freelancer_profile
  belongs_to :client_contact
  has_one :client, through: :client_contact
  belongs_to :client
  belongs_to :specialty
end
