class AddLocationToCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :candidates, :location, :string
  end
end
