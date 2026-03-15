class AddPerformanceSnapshotToFreelancerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :freelancer_profiles, :performance_snapshot, :jsonb, default: {}, null: false
  end
end
