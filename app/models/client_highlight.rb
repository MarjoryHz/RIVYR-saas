class ClientHighlight < ApplicationRecord
  belongs_to :client

  validates :title, presence: true, length: { maximum: 50 }
  validates :body, presence: true, length: { maximum: 120 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }

  default_scope { order(:position) }
end
