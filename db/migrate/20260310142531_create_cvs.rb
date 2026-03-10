class CreateCvs < ActiveRecord::Migration[8.1]
  def change
    create_table :cvs do |t|
      t.string :title
      t.string :file_url
      t.string :file_name
      t.string :file_type

      t.timestamps
    end
  end
end
