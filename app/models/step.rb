class Step < ApplicationRecord
  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel
  include TinyMceImages
  include ViewableModel
  include ObservableModel

  SEARCHABLE_ATTRIBUTES = ['steps.name', :children].freeze
  SEARCHABLE_IN_PROTOCOL_ATTRIBUTES = ['steps.name'].freeze

  attr_accessor :skip_position_adjust # to be used in bulk deletion

  enum assets_view_mode: { thumbnail: 0, list: 1, inline: 2 }

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :completed, inclusion: { in: [true, false] }
  validates :user, :protocol, presence: true
  validates :completed_on, presence: true, if: proc { |s| s.completed? }
  validates :position, uniqueness: { scope: :protocol }, if: -> { !archived && position_changed? }

  before_validation :set_completed_on, if: :completed_changed?
  before_save :set_last_modified_by
  before_destroy :cascade_before_destroy
  after_destroy :adjust_positions_after_destroy, unless: -> { skip_position_adjust || archived }

  # conditional touch excluding step completion updates
  after_destroy :touch_protocol, :remove_from_user_settings
  after_save :touch_protocol
  after_touch :touch_protocol

  belongs_to :user, inverse_of: :steps
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  belongs_to :protocol, inverse_of: :steps
  belongs_to :original_protocol, class_name: 'Protocol', optional: true, inverse_of: :original_steps
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true

  delegate :team, to: :protocol
  has_many :step_orderable_elements, inverse_of: :step, dependent: :destroy
  has_many :checklists, inverse_of: :step, dependent: :destroy
  has_many :step_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :step_texts, inverse_of: :step, dependent: :destroy
  has_many :step_assets, inverse_of: :step, dependent: :destroy
  has_many :assets, through: :step_assets, dependent: :destroy
  has_many :step_tables, inverse_of: :step, dependent: :destroy
  has_many :tables, through: :step_tables, dependent: :destroy
  has_many :report_elements, inverse_of: :step, dependent: :destroy
  has_many :form_responses, as: :parent, inverse_of: :parent, dependent: :destroy
  has_many :step_results, inverse_of: :step, dependent: :destroy
  has_many :results, through: :step_results

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

  scope :in_order, -> { order(position: :asc) }
  scope :desc_order, -> { order(position: :desc) }

  def self.search(user,
    include_archived,
    query = nil,
    teams = user.teams,
    options = {})
    team_ids = teams.is_a?(ActiveRecord::Relation) ? teams.pluck(:id) : teams.id

    if options[:in_repository]
      steps = joins(:protocol)
      readable_steps = where(protocols: { id: Protocol.readable_by_user(user, team_ids).select(:id) })
      steps = steps.active unless include_archived
    else
      steps = joins(protocol: :my_module)
      readable_steps = joins(protocol: :my_module).where(my_modules: { id: MyModule.readable_by_user(user, team_ids).select(:id) })
      unless include_archived
        steps = steps.active
                    .joins(protocol: { my_module: { experiment: :project } })
                    .where(my_modules: { archived: false }, experiments: { archived: false }, projects: { archived: false })
      end
    end

    steps = steps.with(readable_steps: readable_steps)
              .joins('INNER JOIN "readable_steps" ON "readable_steps"."id" = "steps"."id"')

    steps.where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query, options)
  end

  def self.where_children_attributes_like(query, options = {})

    unscoped_readable_steps = unscoped.joins('INNER JOIN "readable_steps" ON "readable_steps"."id" = "steps"."id"').select(:id)
    sql = "#{unscoped_readable_steps.joins(:step_texts).where_attributes_like(StepText::SEARCHABLE_ATTRIBUTES, query).to_sql}
    UNION ALL
    #{unscoped_readable_steps.joins(step_tables: :table).where_attributes_like(Table::SEARCHABLE_ATTRIBUTES, query).to_sql}
    UNION ALL
    #{unscoped_readable_steps.joins(:checklists).where_attributes_like(Checklist::SEARCHABLE_ATTRIBUTES, query).to_sql}
    UNION ALL
    #{unscoped_readable_steps.joins(checklists: :checklist_items).where_attributes_like(ChecklistItem::SEARCHABLE_ATTRIBUTES, query).to_sql}
    UNION ALL
    #{unscoped_readable_steps.joins(:step_comments).where_attributes_like(StepComment::SEARCHABLE_ATTRIBUTES, query).to_sql}
    "
    unless options[:in_repository]
      sql += "UNION ALL
      #{unscoped_readable_steps.joins(form_responses: :form_field_values).where_attributes_like(FormFieldValue::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION ALL
      #{unscoped_readable_steps.joins(form_responses: :form).where_attributes_like(Form::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION ALL
      #{unscoped_readable_steps.joins(form_responses: { form: :form_fields }).where_attributes_like(FormField::SEARCHABLE_ATTRIBUTES, query).to_sql}
      "
    end
    unscoped.from("(#{sql}) AS steps", :steps)
  end

  def self.filter_by_teams(teams = [])
    return self if teams.blank?

    joins(protocol: { my_module: { experiment: :project } })
      .where(protocol: { my_modules: { experiments: { projects: { team: teams } } } })
  end

  def default_view_state
    { 'assets' => { 'sort' => 'new' } }
  end

  def validate_view_state(view_state)
    unless %w(new old atoz ztoa).include?(view_state.state.dig('assets', 'sort'))
      view_state.errors.add(:state, :wrong_state)
    end
  end

  def self.readable_by_user(user, teams)
    joins(:protocol).where(protocol: { my_module: MyModule.readable_by_user(user, teams) })
  end

  def can_destroy?
    !assets.map(&:locked?).any?
  end

  def my_module
    protocol.present? ? protocol.my_module : nil
  end

  def position_plus_one
    position + 1
  end

  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = StepComment.joins(:step)
                          .where(steps: { id: id })
                          .where('comments.id <  ?', last_id)
                          .order(created_at: :desc)
                          .limit(per_page)
    StepComment.from(comments, :comments).order(created_at: :asc)
  end

  def space_taken
    st = 0
    assets.each do |asset|
      st += asset.estimated_size
    end
    st
  end

  def comments
    step_comments
  end

  def navigable?
    !protocol.my_module.archived? && protocol.my_module.navigable? if protocol.my_module
  end

  def description_step_text
    step_texts.order(created_at: :asc).first
  end

  def duplicate(protocol, user, step_position: nil, step_name: nil, include_file_versions: false, original_protocol: nil)
    ActiveRecord::Base.transaction do
      assets_to_clone = []

      new_step = protocol.steps.new(
        name: step_name || name,
        position: step_position || protocol.steps.length,
        completed: false,
        user: user,
        original_protocol: original_protocol
      )
      new_step.save!

      # Copy texts
      step_texts.each do |step_text|
        step_text.duplicate(new_step, step_text.step_orderable_element.position)
      end

      # Copy checklists
      checklists.asc.each do |checklist|
        checklist.duplicate(new_step, user, checklist.step_orderable_element.position)
      end

      # "Shallow" Copy assets
      assets.each do |asset|
        new_asset = asset.dup
        new_asset.update!(created_by: user, last_modified_by: user)
        new_step.assets << new_asset
        assets_to_clone << [asset.id, new_asset.id]
      end

      # Copy tables
      tables.each do |table|
        duplicate_table(new_step, user, table)
      end

      # Copy form responses
      form_responses.each do |form_response|
        form_response.duplicate(new_step, user, form_response.step_orderable_element.position)
      end

      # Call clone helper
      Protocol.delay(queue: :assets).deep_clone_assets(assets_to_clone, include_file_versions)

      new_step
    end
  end

  def normalize_elements_position
    step_orderable_elements.active.order(:position).each_with_index do |element, index|
      element.update!(position: index) unless element.position == index
    end
  end

  def next_element_position
    current_position = step_orderable_elements.active.order(position: :asc).last&.position

    current_position.nil? ? 0 : current_position + 1
  end

  def label
    I18n.t('protocols.steps.label', name: name, position: position + 1)
  end

  private

  def duplicate_table(new_step, user, table)
    table.duplicate(new_step, user, table.step_table.step_orderable_element.position)
  end

  def remove_from_user_settings
    CleanupUserSettingsJob.perform_later('task_step_states', id)
  end

  def touch_protocol
    # don't touch if in a no_touching block
    return if ActiveRecord::NoTouching.applied_to?(Protocol)

    # if only step completion attributes were changed, do not touch protocol
    return if saved_changes.keys.sort == %w(completed completed_on updated_at)

    # rubocop:disable Rails/SkipsModelValidations
    protocol.update(last_modified_by: last_modified_by) if last_modified_by
    protocol.touch
    # rubocop:enable Rails/SkipsModelValidations
  end

  def adjust_positions_after_destroy
    re_index_following_steps
    protocol.steps.where('position > ?', position).order(:position).each do |step|
      step.update!(position: step.position - 1)
    end
  end

  def re_index_following_steps
    steps = protocol.steps.where(position: position..).order(:position).where.not(id: id)
    i = position
    steps.each do |step|
      i += 1
      step.position = i
    end

    steps.reverse_each do |step|
      step.save! if step.position_changed?
    end
  end

  def cascade_before_destroy
    assets.each(&:destroy)
    tables.each(&:destroy)
    form_responses.each(&:destroy)
  end

  def set_completed_on
    return if completed? && completed_on.present?

    self.completed_on = completed? ? DateTime.now : nil
  end

  def set_last_modified_by
    self.last_modified_by_id ||= user_id
  end
end
