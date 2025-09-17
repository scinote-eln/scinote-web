# frozen_string_literal: true

class ResultComment < Comment
  include ObservableModel

  before_create :fill_unseen_by

  belongs_to :result, foreign_key: :associated_id, inverse_of: :result_comments

  validates :result, presence: true

  def commentable
    result
  end

  private

  def fill_unseen_by
    self.unseen_by += result.my_module.experiment.project.users.where.not(id: user.id).pluck(:id)
  end

  # Override for ObservableModel
  def changed_by
    last_modified_by || user
  end
end
