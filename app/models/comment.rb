class Comment < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :message, nullify: false
  validates :message,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :user, presence: true

  belongs_to :user, inverse_of: :comments
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    _current_team = nil,
    options = {}
  )
    project_ids =
      Project
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)
    my_module_ids =
      MyModule
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)
    step_ids =
      Step
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)
    result_ids =
      Result
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    new_query =
      Comment.distinct
             .joins(:user)
             .where(
               '(comments.associated_id IN (?) AND comments.type = ?) OR ' \
               '(comments.associated_id IN (?) AND comments.type = ?) OR ' \
               '(comments.associated_id IN (?) AND comments.type = ?) OR ' \
               '(comments.associated_id IN (?) AND comments.type = ?)',
               project_ids, 'ProjectComment',
               my_module_ids, 'TaskComment',
               step_ids, 'StepComment',
               result_ids, 'ResultComment'
             )
             .where_attributes_like(['message', 'users.full_name'],
                                    query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end
end
