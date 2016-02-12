class Step < ActiveRecord::Base
  include SearchableModel

  validates :name, presence: true,
    length: { maximum: 50 }
  validates :description,
    length: { maximum: 1000}
  validates :position, presence: true
  validates :completed, inclusion: { in: [true, false] }
  validates :user, :my_module, presence: true
  validates :completed_on, presence: true, if: "completed?"

  belongs_to :user, inverse_of: :steps
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :my_module, inverse_of: :steps
  has_many :checklists, inverse_of: :step,
    dependent: :destroy
  has_many :step_comments, inverse_of: :step,
    dependent: :destroy
  has_many :comments, through: :step_comments
  has_many :step_assets, inverse_of: :step,
    dependent: :destroy
  has_many :assets, through: :step_assets
  has_many :step_tables, inverse_of: :step,
    dependent: :destroy
  has_many :tables, through: :step_tables
  has_many :report_elements, inverse_of: :step,
    dependent: :destroy

  accepts_nested_attributes_for :checklists,
    reject_if: :all_blank,
    allow_destroy: true
  accepts_nested_attributes_for :assets,
    reject_if: :all_blank,
    allow_destroy: true
  accepts_nested_attributes_for :tables,
    reject_if: :all_blank,
    allow_destroy: true

  after_destroy :cascade_after_destroy
  before_save :set_last_modified_by

  def self.search(user, include_archived, query = nil, page = 1)
    module_ids =
      MyModule
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")

    new_query = Step
      .distinct
      .where("steps.my_module_id IN (?)", module_ids)
      .where_attributes_like(:name, query)

    # Show all results if needed
    if page == SHOW_ALL_RESULTS
      new_query
    else
      new_query
        .limit(SEARCH_LIMIT)
        .offset((page - 1) * SEARCH_LIMIT)
    end
  end

  def destroy(current_user)
    @current_user = current_user

    # Store IDs of comments, assets & tables so they
    # can be destroyed in after_destroy
    @c_ids = self.comments.collect { |c| c.id }
    @a_ids = self.assets.collect { |a| a.id }
    @t_ids = self.tables.collect { |t| t.id }

    super()
  end

  def last_comments(last_id = 1, per_page = 20)
    last_id = 9999999999999 if last_id <= 1
    Comment.joins(:step_comment)
    .where(step_comments: {step_id: id})
    .where('comments.id <  ?', last_id)
    .order(created_at: :desc)
    .limit(per_page)
  end

  def save(current_user=nil)
    @current_user = current_user
    super()
  end

  def space_taken
    st = 0
    assets.each do |asset|
      st += asset.estimated_size
    end
    st
  end

  protected

  def cascade_after_destroy
    Comment.destroy(@c_ids)
    @c_ids = nil
    Asset.destroy(@a_ids)
    @a_ids = nil
    Table.destroy(@t_ids)
    @t_ids = nil

    # Generate "delete" activity
    Activity.create(
      type_of: :destroy_step,
      project: my_module.project,
      my_module: my_module,
      user: @current_user,
      message: I18n.t(
        "activities.destroy_step",
        user: @current_user.full_name,
        step: position + 1,
        step_name: name
      )
    )
  end

  def set_last_modified_by
    if @current_user
      self.tables.each do |t|
        t.created_by ||= @current_user
        t.last_modified_by = @current_user if t.changed?
      end
      self.assets.each do |a|
        a.created_by ||= @current_user
        a.last_modified_by = @current_user if a.changed?
      end
      self.checklists.each do |checklist|
        checklist.created_by ||= @current_user
        checklist.last_modified_by = @current_user if checklist.changed?
        checklist.checklist_items.each do |checklist_item|
          checklist_item.created_by ||= @current_user
          checklist_item.last_modified_by = @current_user if checklist_item.changed?
        end
      end
    end
  end
end

