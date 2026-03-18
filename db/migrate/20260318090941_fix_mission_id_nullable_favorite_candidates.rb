class FixMissionIdNullableFavoriteCandidates < ActiveRecord::Migration[8.1]
  def change
    change_column_null :favorite_candidates, :mission_id, true
  end
end
