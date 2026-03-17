class AddWorkflowFieldsToPlacements < ActiveRecord::Migration[8.1]
  def change
    change_table :placements, bulk: true do |t|
      t.references :freelancer_profile, foreign_key: true
      t.string :workflow_status, null: false, default: "in_progress"
      t.string :package_summary
      t.boolean :client_offer_compliant
      t.boolean :candidate_accepted
      t.datetime :admin_reviewed_at
      t.references :admin_reviewed_by, foreign_key: { to_table: :users }
      t.text :admin_review_note
    end

    add_index :placements, :workflow_status
  end
end
