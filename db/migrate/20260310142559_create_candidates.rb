class CreateCandidates < ActiveRecord::Migration[8.1]
  def change
    create_table :candidates do |t|
      t.references :cv, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :linkedin_url
      t.string :status
      t.text :notes
      t.string :source

      t.timestamps
    end
  end
end
