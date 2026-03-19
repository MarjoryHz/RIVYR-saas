class AddBankAccountsToFreelancerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :freelancer_profiles, :primary_bank_account_label, :string
    add_column :freelancer_profiles, :primary_bank_iban, :string
    add_column :freelancer_profiles, :primary_bank_bic, :string
    add_column :freelancer_profiles, :secondary_bank_account_label, :string
    add_column :freelancer_profiles, :secondary_bank_iban, :string
    add_column :freelancer_profiles, :secondary_bank_bic, :string
  end
end
