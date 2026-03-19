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
  has_many :client_subscriptions, dependent: :destroy
  has_many :subscribed_clients, through: :client_subscriptions, source: :client

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :role, presence: true

  def display_first_name
    first_name.to_s.gsub(/\d+\z/, "").strip
  end

  def display_last_name
    last_name.to_s.gsub(/\d+\z/, "").strip
  end

  def display_name
    [ display_first_name, display_last_name ].reject(&:blank?).join(" ").presence || email.to_s
  end

  def avatar_image_path
    return avatar_path if respond_to?(:avatar_path) && avatar_path.present?

    respond_to?(:profile_gender) && profile_gender.to_s == "female" ? "avatars/femme-avatar.png" : "avatars/homme-avatar.png"
  end
end
