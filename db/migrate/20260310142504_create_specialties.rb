class CreateSpecialties < ActiveRecord::Migration[8.1]
  def change
    create_table :specialties do |t|
      t.string :name
      t.string :options, array: true, default: []

      t.timestamps
    end
  end
end
