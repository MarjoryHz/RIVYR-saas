class User < ApplicationRecord
  enum :role, {
    freelance: "freelance",
    client: "client",
    candidate: "candidate",
    admin: "admin"
  }, prefix: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :freelancer_profile
  has_one :client_contact
  has_one :candidate
  has_many :payout_requests, dependent: :destroy
  has_many :todo_categories, dependent: :destroy
  has_many :todo_tasks, dependent: :destroy
  has_many :favorite_missions, dependent: :destroy
  has_many :favorited_missions, through: :favorite_missions, source: :mission
  has_many :favorite_candidates, dependent: :destroy
  has_many :candidate_notes, dependent: :destroy
  has_many :favorited_candidates, through: :favorite_candidates, source: :candidate

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :role, presence: true
end
