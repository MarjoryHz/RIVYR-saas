class CreateFreelancerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :freelancer_profiles do |t|
      t.references :region, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :specialty, null: false, foreign_key: true
      t.string :operational_status
      t.string :availability_status
      t.text :bio
      t.string :linkedin_url
      t.string :website_url
      t.integer :rivyr_score_current
      t.boolean :profile_private

      t.timestamps
    end
  end
end
