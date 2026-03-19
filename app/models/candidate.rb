class Candidate < ApplicationRecord
  enum :status, {
    new: "new",
    qualified: "qualified",
    presented: "presented",
    interviewing: "interviewing",
    placed: "placed"
  }, prefix: true

  enum :availability, {
    immediate:      "immediate",
    one_month:      "one_month",
    three_months:   "three_months",
    six_months:     "six_months",
    other:          "other"
  }, prefix: true, allow_nil: true

  AVAILABILITY_LABELS = {
    "immediate"    => "Immédiate",
    "one_month"    => "Préavis d'1 mois",
    "three_months" => "Préavis de 3 mois",
    "six_months"   => "Préavis de 6 mois",
    "other"        => "Autre"
  }.freeze

  CONTRACT_LABELS = {
    "cdi"                   => "CDI",
    "cdd"                   => "CDD",
    "freelance"             => "Freelance",
    "interim"               => "Intérim",
    "management_transition" => "Management de transition"
  }.freeze

  SALARY_RANGES = [
    "< 30k€", "30 – 40k€", "40 – 50k€", "50 – 60k€",
    "60 – 75k€", "75 – 90k€", "90 – 110k€", "> 110k€"
  ].freeze

  LANGUAGE_FLAGS = {
    "fr" => "🇫🇷", "en" => "🇬🇧", "es" => "🇪🇸", "de" => "🇩🇪",
    "it" => "🇮🇹", "pt" => "🇵🇹", "nl" => "🇳🇱", "ar" => "🇲🇦",
    "zh" => "🇨🇳", "ja" => "🇯🇵"
  }.freeze

  LANGUAGE_NAMES = {
    "fr" => "Français", "en" => "Anglais",    "es" => "Espagnol", "de" => "Allemand",
    "it" => "Italien",  "pt" => "Portugais",  "nl" => "Néerlandais", "ar" => "Arabe",
    "zh" => "Chinois",  "ja" => "Japonais"
  }.freeze

  LANGUAGE_LEVELS = {
    "bilingual"    => "Bilingue",
    "professional" => "Professionnel",
    "partial"      => "Notions"
  }.freeze

  has_many :placements, dependent: :nullify
  has_many :favorite_candidates, dependent: :destroy
  has_many :candidate_notes, dependent: :destroy
  has_many :work_experiences, -> { ordered }, dependent: :destroy
  has_many :educations,       -> { ordered }, dependent: :destroy
  has_many :contributions, dependent: :destroy
  belongs_to :user, optional: true

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :job_titles, :skills, length: { maximum: 20 }, allow_nil: true

  def display_first_name
    first_name.to_s.gsub(/\d+\z/, "").strip
  end

  def display_last_name
    last_name.to_s.gsub(/\d+\z/, "").strip
  end

  def display_name
    [ display_first_name, display_last_name ].reject(&:blank?).join(" ")
  end

  def initials
    [ display_first_name, display_last_name ].filter_map { |part| part.to_s.first }.join.upcase.first(2)
  end

  def avatar_image_path
    return avatar_path if respond_to?(:avatar_path) && avatar_path.present?

    respond_to?(:profile_gender) && profile_gender.to_s == "female" ? "avatars/femme-avatar.png" : "avatars/homme-avatar.png"
  end

  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :search, lambda { |q|
    return all if q.blank?

    where(
      "first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR source ILIKE :q",
      q: "%#{q}%"
    )
  }
end
