class ChangeClientPostReactionsUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :client_post_reactions, [:client_post_id, :user_id, :emoji], if_exists: true
    add_index :client_post_reactions, [:client_post_id, :user_id], unique: true
  end
end
