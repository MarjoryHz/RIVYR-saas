class CreateClientPostCommentReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :client_post_comment_reactions do |t|
      t.references :client_post_comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji, null: false

      t.timestamps
    end

    add_index :client_post_comment_reactions, [:client_post_comment_id, :user_id], unique: true, name: "index_comment_reactions_on_comment_and_user"
  end
end
