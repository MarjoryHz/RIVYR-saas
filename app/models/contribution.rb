class Contribution < ApplicationRecord
  belongs_to :candidate

  enum :kind, {
    ai_response:          "ai_response",
    open_to_opportunity:  "open_to_opportunity",
    new_experience:       "new_experience",
    new_education:        "new_education"
  }, prefix: true

  KIND_LABELS = {
    "ai_response"         => "Réponse thématique",
    "open_to_opportunity" => "À l'écoute",
    "new_experience"      => "Nouveau poste",
    "new_education"       => "Nouvelle formation"
  }.freeze

  KIND_ICONS = {
    "ai_response"         => "fa-solid fa-brain",
    "open_to_opportunity" => "fa-solid fa-circle-dot",
    "new_experience"      => "fa-regular fa-building",
    "new_education"       => "fa-solid fa-graduation-cap"
  }.freeze

  scope :published, -> { where(published: true).order(published_at: :desc) }
end
