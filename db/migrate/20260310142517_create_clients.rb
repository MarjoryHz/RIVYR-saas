class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :ownership_type
      t.string :legal_name
      t.string :brand_name
      t.string :sector
      t.string :website_url
      t.text :location
      t.string :company_size
      t.text :bio
      t.boolean :active

      t.timestamps
    end
  end
end
