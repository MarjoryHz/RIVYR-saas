class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :freelancer_profile

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
end
