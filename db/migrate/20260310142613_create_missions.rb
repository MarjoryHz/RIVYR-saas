class CreateMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :missions do |t|
      t.references :region, null: false, foreign_key: true
      t.references :freelancer_profile, null: false, foreign_key: true
      t.references :client_contact, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :specialty, null: false, foreign_key: true
      t.string :mission_type
      t.string :title
      t.string :reference
      t.string :status
      t.text :location
      t.boolean :contract_signed
      t.date :opened_at
      t.date :started_at
      t.date :closed_at
      t.string :priority_level
      t.text :brief_summary
      t.text :compensation_summary
      t.text :search_constraints
      t.string :origin_type

      t.timestamps
    end
  end
end
