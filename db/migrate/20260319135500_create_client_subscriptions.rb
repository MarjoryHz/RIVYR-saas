class CreateClientSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :client_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end

    add_index :client_subscriptions, [ :user_id, :client_id ], unique: true
  end
end
