class CreateWorkExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :work_experiences do |t|
      t.references :candidate, null: false, foreign_key: true
      t.string  :title,    null: false
      t.string  :company
      t.integer :start_year
      t.integer :start_month
      t.integer :end_year
      t.integer :end_month
      t.string  :skills, array: true, default: []
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
