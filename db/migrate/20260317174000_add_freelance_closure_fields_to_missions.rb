class AddFreelanceClosureFieldsToMissions < ActiveRecord::Migration[8.1]
  def change
    change_table :missions, bulk: true do |t|
      t.string :closure_reason
      t.text :closure_note
      t.datetime :closed_by_freelancer_at
      t.datetime :closure_admin_read_at
    end
  end
end
