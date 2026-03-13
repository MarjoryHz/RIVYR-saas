class TodoTask < ApplicationRecord
  enum :status, {
    todo: "todo",
    in_progress: "in_progress",
    done: "done"
  }, prefix: true

  enum :priority, {
    low: "low",
    medium: "medium",
    high: "high"
  }, prefix: true

  belongs_to :user
  belongs_to :todo_category

  validates :title, presence: true
  validates :status, presence: true
  validates :priority, presence: true

  scope :ordered, lambda {
    order(
      Arel.sql("CASE status WHEN 'todo' THEN 0 WHEN 'in_progress' THEN 1 ELSE 2 END"),
      Arel.sql("CASE priority WHEN 'high' THEN 0 WHEN 'medium' THEN 1 ELSE 2 END"),
      :due_on,
      created_at: :desc
    )
  }
end
