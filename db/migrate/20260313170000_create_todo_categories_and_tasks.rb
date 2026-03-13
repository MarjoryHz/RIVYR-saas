class CreateTodoCategoriesAndTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :todo_categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :system, null: false, default: false

      t.timestamps
    end

    add_index :todo_categories, [ :user_id, :name ], unique: true

    create_table :todo_tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :todo_category, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "todo"
      t.string :priority, null: false, default: "medium"
      t.date :due_on

      t.timestamps
    end

    add_index :todo_tasks, :status
    add_index :todo_tasks, :priority
  end
end
