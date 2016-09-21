class Comment < ActiveRecord::Base
  include SearchableModel

  auto_strip_attributes :message, nullify: false
  validates :message, presence: true, length: { maximum: TEXT_MAX_LENGTH }
  validates :user, presence: true

  validate :belongs_to_only_one_object

  belongs_to :user, inverse_of: :comments
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'

  has_one :step_comment, inverse_of: :comment, dependent: :destroy
  has_one :my_module_comment, inverse_of: :comment, dependent: :destroy
  has_one :result_comment, inverse_of: :comment, dependent: :destroy
  has_one :sample_comment, inverse_of: :comment, dependent: :destroy
  has_one :project_comment, inverse_of: :comment, dependent: :destroy

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1
  )
    project_ids =
      Project
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")
    my_module_ids =
      MyModule
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")
    step_ids =
      Step
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")
    result_ids =
      Result
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")


    if query
      a_query = query.strip
      .gsub("_","\\_")
      .gsub("%","\\%")
      .split(/\s+/)
      .map {|t|  "%" + t + "%" }
    else
      a_query = query
    end

    new_query = Comment
      .distinct
      .joins(:user)
      .joins("LEFT JOIN project_comments ON project_comments.comment_id = comments.id")
      .joins("LEFT JOIN my_module_comments ON my_module_comments.comment_id = comments.id")
      .joins("LEFT JOIN step_comments ON step_comments.comment_id = comments.id")
      .joins("LEFT JOIN result_comments ON result_comments.comment_id = comments.id")
      .where(
        "project_comments.project_id IN (?) OR " +
        "my_module_comments.my_module_id IN (?) OR " +
        "step_comments.step_id IN (?) OR " +
        "result_comments.result_id IN (?)",
        project_ids,
        my_module_ids,
        step_ids,
        result_ids
      )
      .where_attributes_like(
        [ :message, "users.full_name" ],
        a_query
      )

      # Show all results if needed
      if page == SHOW_ALL_RESULTS
        new_query
      else
        new_query
          .limit(SEARCH_LIMIT)
          .offset((page - 1) * SEARCH_LIMIT)
      end
  end

  private

  def belongs_to_only_one_object
    # We must allow all elements to be blank because of GUI
    # (eventhough it's not really a "valid" comment)
    cntr = 0
    cntr += 1 if step_comment.present?
    cntr += 1 if my_module_comment.present?
    cntr += 1 if result_comment.present?
    cntr += 1 if sample_comment.present?
    cntr += 1 if project_comment.present?

    if cntr > 1
      errors.add(:base, "Comment can only belong to 1 'parent' object.")
    end
  end

end
