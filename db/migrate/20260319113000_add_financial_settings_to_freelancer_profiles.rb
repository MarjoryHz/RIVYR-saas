class AddFinancialSettingsToFreelancerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :freelancer_profiles, :freelance_legal_status, :string
    add_column :freelancer_profiles, :annual_revenue_target_eur, :integer
    add_column :freelancer_profiles, :monthly_revenue_targets_eur, :jsonb, default: {}, null: false
  end
end
