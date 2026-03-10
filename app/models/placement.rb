class Placement < ApplicationRecord
  belongs_to :mission
  belongs_to :candidate
end
