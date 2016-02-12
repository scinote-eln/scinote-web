class SampleComment < ActiveRecord::Base
  validates :comment, :sample, presence: true
  validates :sample_id, uniqueness: { scope: :comment_id }

  belongs_to :comment, inverse_of: :sample_comment
  belongs_to :sample, inverse_of: :sample_comments
end
