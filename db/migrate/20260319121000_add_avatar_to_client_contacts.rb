class AddAvatarToClientContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :client_contacts, :avatar, :string
  end
end
