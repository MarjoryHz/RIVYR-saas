class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :full_name, :string
  attribute :email, :string
  attribute :company, :string
  attribute :subject, :string
  attribute :message, :string

  validates :full_name, :email, :subject, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, length: { minimum: 20 }

  def submit
    return false unless valid?

    Rails.logger.info(
      "[ContactForm] #{full_name} <#{email}> | #{company.presence || 'Sans entreprise'} | #{subject}"
    )
    true
  end
end
