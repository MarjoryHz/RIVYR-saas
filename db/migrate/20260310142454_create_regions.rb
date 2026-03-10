class CreateRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :regions do |t|
      t.string :name
      t.string :options, array: true, default: []

      t.timestamps
    end
  end
end
