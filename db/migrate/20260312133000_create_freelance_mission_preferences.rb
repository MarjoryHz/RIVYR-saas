class CreateFreelanceMissionPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :freelance_mission_preferences do |t|
      t.references :freelancer_profile, null: false, foreign_key: true
      t.references :mission, null: false, foreign_key: true
      t.boolean :urgent, null: false, default: false

      t.timestamps
    end

    add_index :freelance_mission_preferences, [ :freelancer_profile_id, :mission_id ], unique: true, name: "index_freelance_mission_preferences_on_profile_and_mission"
  end
end
