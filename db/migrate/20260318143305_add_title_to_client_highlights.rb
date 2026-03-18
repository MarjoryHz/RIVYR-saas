class AddTitleToClientHighlights < ActiveRecord::Migration[8.1]
  def change
    add_column :client_highlights, :title, :string
  end
end
