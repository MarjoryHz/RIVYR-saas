class CreateClientContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :client_contacts do |t|
      t.references :client, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :job_title
      t.boolean :primary_contact

      t.timestamps
    end
  end
end
