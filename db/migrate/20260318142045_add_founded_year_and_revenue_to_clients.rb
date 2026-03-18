class AddFoundedYearAndRevenueToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :founded_year, :integer
    add_column :clients, :revenue, :string
  end
end
