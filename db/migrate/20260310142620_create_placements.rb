class CreatePlacements < ActiveRecord::Migration[8.1]
  def change
    create_table :placements do |t|
      t.references :mission, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.string :status
      t.date :hired_at
      t.integer :annual_salary_cents
      t.integer :placement_fee_cents
      t.text :notes

      t.timestamps
    end
  end
end
