class CreateFreelanceMissionApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :freelance_mission_applications do |t|
      t.references :mission, null: false, foreign_key: true
      t.references :freelancer_profile, null: false, foreign_key: true
      t.string :status, null: false, default: "applied"
      t.datetime :applied_at
      t.datetime :submitted_to_client_at
      t.datetime :client_validated_at
      t.datetime :client_rejected_at
      t.text :note

      t.timestamps
    end

    add_index :freelance_mission_applications, [ :mission_id, :freelancer_profile_id ], unique: true, name: "index_freelance_mission_applications_uniqueness"
    add_index :freelance_mission_applications, :status
  end
end
