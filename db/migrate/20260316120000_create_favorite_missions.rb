class CreateFavoriteMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :favorite_missions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :mission, null: false, foreign_key: true

      t.timestamps
    end

    add_index :favorite_missions, [ :user_id, :mission_id ], unique: true
  end
end
