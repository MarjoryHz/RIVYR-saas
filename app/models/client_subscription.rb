class ClientSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :client

  validates :user_id, uniqueness: { scope: :client_id }
end
