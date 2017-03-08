class Comment < ActiveRecord::Base
  include SearchableModel

  auto_strip_attributes :message, nullify: false
  validates :message,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :user, presence: true

  belongs_to :user, inverse_of: :comments
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id',
             class_name: 'User'

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1
  )
    project_ids =
      Project
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .select(:id)
    my_module_ids =
      MyModule
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .select(:id)
    step_ids =
      Step
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .select(:id)
    result_ids =
      Result
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .select(:id)

    if query
      a_query = query.strip
                     .gsub('_', '\\_')
                     .gsub('%', '\\%')
                     .split(/\s+/)
                     .map { |t| '%' + t + '%' }
    else
      a_query = query
    end

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
             .where_attributes_like([:message, 'users.full_name'], a_query)

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
