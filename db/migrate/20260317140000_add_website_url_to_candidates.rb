class AddWebsiteUrlToCandidates < ActiveRecord::Migration[8.1]
  def change
    add_column :candidates, :website_url, :string
  end
end
