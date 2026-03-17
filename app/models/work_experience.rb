class WorkExperience < ApplicationRecord
  belongs_to :candidate

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc, start_year: :desc, start_month: :desc) }

  def current?
    end_year.nil?
  end

  def date_range
    start_str = format_date(start_year, start_month)
    end_str   = current? ? "Aujourd'hui" : format_date(end_year, end_month)
    "#{start_str} — #{end_str}"
  end

  private

  MONTHS_FR = %w[jan. fév. mars avr. mai juin juil. août sept. oct. nov. déc.].freeze

  def format_date(year, month)
    return year.to_s if year.nil? || month.nil?
    "#{MONTHS_FR[month - 1]} #{year}"
  end
end
