class ResultComment < ActiveRecord::Base
  validates :result, :comment, presence: true
  validates :result_id, uniqueness: { scope: :comment_id }

  belongs_to :result, inverse_of: :result_comments
  belongs_to :comment, inverse_of: :result_comment
end
