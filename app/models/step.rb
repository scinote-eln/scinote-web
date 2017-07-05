class Step < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :position, presence: true
  validates :completed, inclusion: { in: [true, false] }
  validates :user, :protocol, presence: true
  validates :completed_on, presence: true, if: proc { |s| s.completed? }

  belongs_to :user, inverse_of: :steps, optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  belongs_to :protocol,
             inverse_of: :steps,
             optional: true
  has_many :checklists, inverse_of: :step,
    dependent: :destroy
  has_many :step_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :step_assets, inverse_of: :step,
    dependent: :destroy
  has_many :assets, through: :step_assets
  has_many :step_tables, inverse_of: :step,
    dependent: :destroy
  has_many :tables, through: :step_tables
  has_many :report_elements, inverse_of: :step,
    dependent: :destroy
  has_many :tiny_mce_assets, inverse_of: :step, dependent: :destroy

  accepts_nested_attributes_for :checklists,
                                reject_if: :all_blank,
                                allow_destroy: true
  accepts_nested_attributes_for :assets,
                                reject_if: :all_blank,
                                allow_destroy: true
  accepts_nested_attributes_for :tables,
                                reject_if: proc { |attributes|
                                  attributes['contents'].blank?
                                },
                                allow_destroy: true

  after_destroy :cascade_after_destroy
  before_save :set_last_modified_by

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    protocol_ids =
      Protocol
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    new_query = Step
                .distinct
                .where('steps.protocol_id IN (?)', protocol_ids)
                .where_attributes_like([:name, :description], query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def destroy(current_user)
    @current_user = current_user

    # Store IDs of assets & tables so they
    # can be destroyed in after_destroy
    @a_ids = self.assets.collect { |a| a.id }
    @t_ids = self.tables.collect { |t| t.id }

    super()
  end

  def can_destroy?
    !assets.map(&:locked?).any?
  end

  def my_module
    protocol.present? ? protocol.my_module : nil
  end

  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = StepComment.joins(:step)
                          .where(steps: { id: id })
                          .where('comments.id <  ?', last_id)
                          .order(created_at: :desc)
                          .limit(per_page)
    comments.reverse
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
    # Assets already deleted by here
    @a_ids = nil
    Table.destroy(@t_ids)
    @t_ids = nil

    # Generate "delete" activity, but only if protocol is
    # located inside module
    if (protocol.my_module.present?) then
      Activity.create(
        type_of: :destroy_step,
        project: protocol.my_module.experiment.project,
        experiment: protocol.my_module.experiment,
        my_module: protocol.my_module,
        user: @current_user,
        message: I18n.t(
          "activities.destroy_step",
          user: @current_user.full_name,
          step: position + 1,
          step_name: name
        )
      )
    end
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
