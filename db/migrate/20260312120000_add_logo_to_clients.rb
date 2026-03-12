class AddLogoToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :logo, :string
  end
end
