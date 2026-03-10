class Specialty < ApplicationRecord
  has_many :freelancer_profiles, dependent: :nullify
  has_many :missions, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :options
end
