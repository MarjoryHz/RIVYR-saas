class FreelanceMissionApplication < ApplicationRecord
  enum :status, {
    applied: "applied",
    client_review: "client_review",
    accepted: "accepted",
    rejected: "rejected"
  }, prefix: true

  belongs_to :mission
  belongs_to :freelancer_profile
  belongs_to :reviewed_by, class_name: "User", optional: true

  validates :status, presence: true
  validates :mission_id, uniqueness: { scope: :freelancer_profile_id }
  validates :review_reason, length: { maximum: 2_000 }, allow_blank: true, if: -> { self.class.supports_review_reason? }

  scope :pending_validation, -> { where(status: %w[applied client_review]) }
  scope :with_unread_freelance_decision, lambda {
    if column_names.include?("freelancer_notified_at")
      where(status: %w[accepted rejected], freelancer_notified_at: nil)
    else
      none
    end
  }

  def self.supports_review_tracking?
    @supports_review_tracking ||= column_names.include?("reviewed_by_id")
  end

  def self.supports_review_reason?
    @supports_review_reason ||= column_names.include?("review_reason")
  end

  def self.supports_freelancer_notification_tracking?
    @supports_freelancer_notification_tracking ||= column_names.include?("freelancer_notified_at")
  end
end
