class CreateClientPostReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :client_post_reactions do |t|
      t.references :client_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji, null: false, default: "👍"

      t.timestamps
    end
    add_index :client_post_reactions, [:client_post_id, :user_id, :emoji], unique: true, name: "index_reactions_unique_per_user_emoji"
  end
end
