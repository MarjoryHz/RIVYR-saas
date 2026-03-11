class ClientContact < ApplicationRecord
  belongs_to :client
  has_many :missions, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :job_title, length: { maximum: 255 }, allow_blank: true
end
