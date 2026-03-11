class AddAccessControlFields < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "candidate"

    add_reference :client_contacts, :user, foreign_key: true, index: { unique: true, where: "user_id IS NOT NULL" }

    add_reference :candidates, :user, foreign_key: true, index: { unique: true, where: "user_id IS NOT NULL" }
  end
end
