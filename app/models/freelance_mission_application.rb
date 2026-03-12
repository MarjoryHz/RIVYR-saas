class FreelanceMissionApplication < ApplicationRecord
  enum :status, {
    applied: "applied",
    client_review: "client_review",
    accepted: "accepted",
    rejected: "rejected"
  }, prefix: true

  belongs_to :mission
  belongs_to :freelancer_profile

  validates :status, presence: true
  validates :mission_id, uniqueness: { scope: :freelancer_profile_id }

  scope :pending_validation, -> { where(status: %w[applied client_review]) }
end
