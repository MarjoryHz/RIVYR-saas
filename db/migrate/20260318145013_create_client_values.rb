class CreateClientValues < ActiveRecord::Migration[8.1]
  def change
    create_table :client_values do |t|
      t.references :client, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.integer :position

      t.timestamps
    end
  end
end
