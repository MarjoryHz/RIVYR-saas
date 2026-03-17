class CreateEducations < ActiveRecord::Migration[8.1]
  def change
    create_table :educations do |t|
      t.references :candidate, null: false, foreign_key: true
      t.string  :category,    null: false  # diploma | certification | formation
      t.string  :title,       null: false
      t.string  :institution
      t.integer :start_year
      t.integer :start_month
      t.integer :end_year
      t.integer :end_month
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
