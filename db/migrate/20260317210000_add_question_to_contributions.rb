class AddQuestionToContributions < ActiveRecord::Migration[8.1]
  def change
    add_column :contributions, :question, :text
  end
end
