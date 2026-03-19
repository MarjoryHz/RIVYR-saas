class AllowDraftMissions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :missions, :client_contact_id, true
    change_column_null :missions, :region_id, true
    change_column_null :missions, :specialty_id, true
  end
end
