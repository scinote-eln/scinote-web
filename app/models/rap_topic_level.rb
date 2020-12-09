class RapTopicLevel < ApplicationRecord
  has_many :rap_project_levels
  belongs_to :rap_program_level
end
