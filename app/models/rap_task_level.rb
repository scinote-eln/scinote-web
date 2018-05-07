class RapTaskLevel < ApplicationRecord
  belongs_to :rap_project_level
  has_many :projects, inverse_of: :RapTaskLevel
end
