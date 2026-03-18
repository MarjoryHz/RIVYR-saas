class AddMissionIdToFavoriteCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :favorite_candidates, :mission_id, :bigint, null: true
    add_foreign_key :favorite_candidates, :missions, column: :mission_id, on_delete: :cascade

    # Drop old unique index (user_id, candidate_id) and replace with (user_id, candidate_id, mission_id)
    remove_index :favorite_candidates, name: "index_favorite_candidates_on_user_id_and_candidate_id"
    add_index :favorite_candidates, [:user_id, :candidate_id, :mission_id],
              unique: true, name: "index_favorite_candidates_uniqueness"
    add_index :favorite_candidates, :mission_id, name: "index_favorite_candidates_on_mission_id"
  end
end
