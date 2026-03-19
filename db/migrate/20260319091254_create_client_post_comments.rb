class CreateClientPostComments < ActiveRecord::Migration[8.1]
  def change
    create_table :client_post_comments do |t|
      t.references :client_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body

      t.timestamps
    end
  end
end
