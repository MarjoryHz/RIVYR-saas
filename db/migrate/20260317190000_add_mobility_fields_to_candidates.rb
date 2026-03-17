class AddMobilityFieldsToCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :candidates, :mobility_zone,   :string
    add_column :candidates, :availability,    :string
    add_column :candidates, :contract_types,  :string, array: true, default: []
    add_column :candidates, :salary_range,    :string
  end
end
