class AddReviewFieldsToFreelanceMissionApplications < ActiveRecord::Migration[8.1]
  def change
    change_table :freelance_mission_applications, bulk: true do |t|
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.text :review_reason
      t.datetime :freelancer_notified_at
    end
  end
end
