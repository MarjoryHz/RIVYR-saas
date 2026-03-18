class AddAmbianceToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :ambiance, :text
  end
end
