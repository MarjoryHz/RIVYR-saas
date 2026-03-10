class Payment < ApplicationRecord
  belongs_to :commission
  belongs_to :invoice
end
