class CreateContributions < ActiveRecord::Migration[8.1]
  def change
    create_table :contributions do |t|
      t.references :candidate, null: false, foreign_key: true
      t.string  :kind,         null: false
      t.text    :content,      null: false
      t.boolean :published,    null: false, default: false
      t.datetime :published_at
      t.timestamps
    end
  end
end
