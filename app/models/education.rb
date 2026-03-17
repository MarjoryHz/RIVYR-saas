class Education < ApplicationRecord
  belongs_to :candidate

  enum :category, {
    diploma:       "diploma",
    certification: "certification",
    formation:     "formation"
  }

  validates :title,    presence: true
  validates :category, presence: true

  scope :ordered, -> { order(position: :asc, end_year: :desc) }

  def date_range
    start_str = format_date(start_year, start_month)
    end_str   = format_date(end_year, end_month)
    return start_str if end_str.blank?
    return end_str   if start_str.blank?
    "#{start_str} — #{end_str}"
  end

  private

  MONTHS_FR = %w[jan. fév. mars avr. mai juin juil. août sept. oct. nov. déc.].freeze

  def format_date(year, month)
    return nil if year.nil?
    return year.to_s if month.nil?
    "#{MONTHS_FR[month - 1]} #{year}"
  end
end
