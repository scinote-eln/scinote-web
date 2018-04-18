class RapProjectLevel < ApplicationRecord
  has_many :rap_task_levels
  belongs_to :rap_topic_level
end
