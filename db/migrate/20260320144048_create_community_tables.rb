class CreateCommunityTables < ActiveRecord::Migration[8.0]
  def change
    create_table :community_channels do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :community_channels, :slug, unique: true

    create_table :community_messages do |t|
      t.references :community_channel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.bigint :parent_id
      t.text :body, null: false
      t.string :tone, default: "member"

      t.timestamps
    end

    add_foreign_key :community_messages, :community_messages, column: :parent_id
    add_index :community_messages, :parent_id

    create_table :community_message_reactions do |t|
      t.references :community_message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji, null: false

      t.timestamps
    end

    add_index :community_message_reactions, [:community_message_id, :user_id, :emoji],
              unique: true, name: "idx_unique_community_reaction"
  end
end
