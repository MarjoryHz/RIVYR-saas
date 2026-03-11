class InvoiceNote < ApplicationRecord
  belongs_to :invoice
  belongs_to :user, optional: true

  validates :body, presence: true
  validates :note_type, presence: true
end
