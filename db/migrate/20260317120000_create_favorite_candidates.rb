class CreateFavoriteCandidates < ActiveRecord::Migration[8.1]
  def change
    create_table :favorite_candidates do |t|
      t.references :user, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true

      t.timestamps
    end

    add_index :favorite_candidates, [ :user_id, :candidate_id ], unique: true
  end
end
