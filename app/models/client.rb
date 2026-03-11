class Client < ApplicationRecord
  has_many :client_contacts, dependent: :destroy
  has_many :missions, through: :client_contacts

  validates :legal_name, presence: true
  validates :sector, length: { maximum: 255 }, allow_blank: true
  validates :website_url, length: { maximum: 255 }, allow_blank: true
  validates :company_size, length: { maximum: 100 }, allow_blank: true
end
