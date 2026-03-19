class CreateClientPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :client_posts do |t|
      t.references :client, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.string :post_type
      t.string :media_url
      t.datetime :published_at

      t.timestamps
    end
  end
end
