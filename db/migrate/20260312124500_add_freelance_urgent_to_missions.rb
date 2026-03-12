class AddFreelanceUrgentToMissions < ActiveRecord::Migration[8.1]
  def change
    add_column :missions, :freelance_urgent, :boolean, default: false, null: false
  end
end
