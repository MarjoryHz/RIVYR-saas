class AddJobTitlesAndSkillsToCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :candidates, :job_titles, :string, array: true, default: []
    add_column :candidates, :skills, :string, array: true, default: []
  end
end
