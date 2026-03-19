class AddProfileGenderAndAvatarPathToUsersAndCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :profile_gender, :string
    add_column :users, :avatar_path, :string

    add_column :candidates, :profile_gender, :string
    add_column :candidates, :avatar_path, :string
  end
end
