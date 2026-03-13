class TodoCategory < ApplicationRecord
  DEFAULT_NAMES = [
    "Missions",
    "Clients",
    "Candidats",
    "Administratif",
    "Finance",
    "Relances"
  ].freeze

  belongs_to :user
  has_many :todo_tasks, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :ordered, -> { order(Arel.sql("LOWER(name) ASC")) }
end
