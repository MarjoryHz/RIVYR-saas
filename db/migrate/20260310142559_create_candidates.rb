class CreateCandidates < ActiveRecord::Migration[8.1]
  def change
    create_table :candidates do |t|
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
