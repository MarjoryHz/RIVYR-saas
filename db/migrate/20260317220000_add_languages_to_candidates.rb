class AddLanguagesToCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :candidates, :languages, :jsonb, default: []
  end
end
