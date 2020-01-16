class MyModule < ApplicationRecord
  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel
  include TinyMceImages

  enum state: Extends::TASKS_STATES

  before_create :create_blank_protocol

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :x, :y, :workflow_order, presence: true
  validates :experiment, presence: true
  validates :my_module_group, presence: true, if: proc { |mm| !mm.my_module_group_id.nil? }
  validate :coordinates_uniqueness_check, if: :active?

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  belongs_to :archived_by,
             foreign_key: 'archived_by_id',
             class_name: 'User',
             optional: true
  belongs_to :restored_by,
             foreign_key: 'restored_by_id',
             class_name: 'User',
             optional: true
  belongs_to :experiment, inverse_of: :my_modules, touch: true
  belongs_to :my_module_group, inverse_of: :my_modules, optional: true
  has_many :results, inverse_of: :my_module, dependent: :destroy
  has_many :my_module_tags, inverse_of: :my_module, dependent: :destroy
  has_many :tags, through: :my_module_tags
  has_many :task_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :inputs,
           class_name: 'Connection',
           foreign_key: 'input_id',
           inverse_of: :to,
           dependent: :destroy
  has_many :outputs,
           class_name: 'Connection',
           foreign_key: 'output_id',
           inverse_of: :from,
           dependent: :destroy
  has_many :my_modules, through: :outputs, source: :to
  has_many :my_module_antecessors,
           through: :inputs,
           source: :from,
           class_name: 'MyModule'
  has_many :sample_my_modules,
           inverse_of: :my_module,
           dependent: :destroy
  has_many :samples, through: :sample_my_modules
  has_many :my_module_repository_rows,
           inverse_of: :my_module, dependent: :destroy
  has_many :repository_rows, through: :my_module_repository_rows
  has_many :user_my_modules, inverse_of: :my_module, dependent: :destroy
  has_many :users, through: :user_my_modules
  has_many :report_elements, inverse_of: :my_module, dependent: :destroy
  has_many :protocols, inverse_of: :my_module, dependent: :destroy
  # Associations for old activity type
  has_many :activities, inverse_of: :my_module

  scope :is_archived, ->(is_archived) { where('archived = ?', is_archived) }
  scope :active, -> { where(archived: false) }
  scope :overdue, -> { where('my_modules.due_date < ?', Time.current.utc) }
  scope :without_group, -> { active.where(my_module_group: nil) }
  scope :one_day_prior, (lambda do
    where('my_modules.due_date > ? AND my_modules.due_date < ?',
          Time.current.utc,
          Time.current.utc + 1.day)
  end)
  scope :workflow_ordered, -> { order(workflow_order: :asc) }
  scope :uncomplete, -> { where(state: 'uncompleted') }

  # A module takes this much space in canvas (x, y) in database
  WIDTH = 30
  HEIGHT = 14

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    current_team = nil,
    options = {}
  )
    exp_ids =
      Experiment
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    if current_team
      experiments_ids = Experiment
                        .search(user,
                                include_archived,
                                nil,
                                1,
                                current_team)
                        .select('id')
      new_query = MyModule
                  .distinct
                  .where('my_modules.experiment_id IN (?)', experiments_ids)
                  .where_attributes_like([:name, :description], query, options)

      if include_archived
        return new_query
      else
        return new_query.where('my_modules.archived = ?', false)
      end
    elsif include_archived
      new_query = MyModule
                  .distinct
                  .where('my_modules.experiment_id IN (?)', exp_ids)
                  .where_attributes_like([:name, :description], query, options)
    else
      new_query = MyModule
                  .distinct
                  .where('my_modules.experiment_id IN (?)', exp_ids)
                  .where('my_modules.archived = ?', false)
                  .where_attributes_like([:name, :description], query, options)
    end

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.viewable_by_user(user, teams)
    where(experiment: Experiment.viewable_by_user(user, teams))
  end

  def navigable?
    !experiment.archived? && experiment.navigable?
  end

  # Removes assigned samples from module and connections with other
  # modules.
  def archive(current_user)
    self.x = 0
    self.y = 0
    # Remove association with module group.
    self.my_module_group = nil

    MyModule.transaction do
      archived = super
      # Unassociate all samples from module.
      archived = SampleMyModule.where(my_module: self).destroy_all if archived
      # Remove all connection between modules.
      archived = Connection.where(input_id: id).delete_all if archived
      archived = Connection.where(output_id: id).delete_all if archived
      unless archived
        raise ActiveRecord::Rollback
      end
    end
    archived
  end

  # Similar as super restore, but also calculate new module position
  def restore(current_user)
    restored = false

    # Calculate new module position
    new_pos = get_new_position
    self.x = new_pos[:x]
    self.y = new_pos[:y]

    MyModule.transaction do
      restored = super

      unless restored
        raise ActiveRecord::Rollback
      end
    end
    experiment.generate_workflow_img
    restored
  end

  def repository_rows_count(repository)
    my_module_repository_rows.joins(repository_row: :repository)
                             .where('repositories.id': repository.id)
                             .count
  end

  def unassigned_users
    User.find_by_sql(
      "SELECT DISTINCT users.id, users.full_name FROM users " +
      "INNER JOIN user_projects ON users.id = user_projects.user_id " +
      "INNER JOIN experiments ON experiments.project_id = user_projects.project_id " +
      "WHERE experiments.id = #{experiment_id.to_s}" +
      " AND users.id NOT IN " +
      "(SELECT DISTINCT user_id FROM user_my_modules WHERE user_my_modules.my_module_id = #{id.to_s})"
    )
  end

  def unassigned_samples
    Sample.where(team_id: experiment.project.team).where.not(id: samples)
  end

  def unassigned_tags
    Tag.find_by_sql(
      "SELECT DISTINCT tags.id, tags.name, tags.color FROM tags " +
      "INNER JOIN experiments ON experiments.project_id = tags.project_id " +
      "WHERE experiments.id = #{experiment_id.to_s} AND tags.id NOT IN " +
      "(SELECT DISTINCT tag_id FROM my_module_tags WHERE my_module_tags.my_module_id = #{id.to_s})"
      )
  end

  def last_activities(count = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    Activity.where(my_module_id: id).order(:created_at).last(count)
  end

  # Get module comments ordered by created_at time. Results are paginated
  # using last comment id and per_page parameters.
  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = TaskComment.joins(:my_module)
                          .where(my_modules: { id: id })
                          .where('comments.id <  ?', last_id)
                          .order(created_at: :desc)
                          .limit(per_page)
    comments.reverse
  end

  def last_activities(last_id = 1,
                      count = Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    Activity.joins(:my_module)
            .where(my_module_id: id)
            .where('activities.id <  ?', last_id)
            .order(created_at: :desc)
            .limit(count)
            .uniq
  end

  def protocol
    # Temporary function (until we fully support
    # multiple protocols per module)
    protocols.count > 0 ? protocols.first : nil
  end

  def first_n_samples(count = Constants::SEARCH_LIMIT)
    samples.order(name: :asc).limit(count)
  end

  def number_of_samples
    samples.count
  end

  def is_overdue?(datetime = DateTime.current)
    due_date.present? && datetime.utc > due_date.end_of_day.utc
  end

  def overdue_for_days(datetime = DateTime.current)
    if due_date.blank? || due_date.end_of_day.utc > datetime.utc
      0
    else
      ((datetime.utc.to_i - due_date.end_of_day.utc.to_i) / 1.day.to_f).ceil
    end
  end

  def is_one_day_prior?(datetime = DateTime.current)
    is_due_in?(datetime, 1.day)
  end

  def is_due_in?(datetime, diff)
    due_date.present? &&
      datetime.utc < due_date.end_of_day.utc &&
      datetime.utc > (due_date.end_of_day.utc - diff)
  end

  def space_taken
    st = 0
    protocol.steps.find_each do |step|
      st += step.space_taken
    end
    results
    .includes(:result_asset)
    .find_each do |result|
      st += result.space_taken
    end
    st
  end

  def archived_results
    results
    .select('results.*')
    .select('ra.id AS result_asset_id')
    .select('rt.id AS result_table_id')
    .select('rx.id AS result_text_id')
    .joins('LEFT JOIN result_assets AS ra ON ra.result_id = results.id')
    .joins('LEFT JOIN result_tables AS rt ON rt.result_id = results.id')
    .joins('LEFT JOIN result_texts AS rx ON rx.result_id = results.id')
    .where(:archived => true)
  end

  # Treat this module as root, get all modules of that subtree
  def downstream_modules
    final = []
    modules = [self]
    until modules.empty?
      my_module = modules.shift
      final << my_module unless final.include?(my_module)
      modules.push(*my_module.my_modules)
    end
    final
  end

  # Treat this module as inversed root, get all modules of that inversed subtree
  def upstream_modules
    final = []
    modules = [self]
    until modules.empty?
      my_module = modules.shift
      final << my_module unless final.include?(my_module)
      modules.push(*my_module.my_module_antecessors)
    end
    final
  end


  # Generate the samples belonging to this module
  # in JSON form, suitable for display in handsontable.js
  def samples_json_hot(order)
    data = []
    samples.order(created_at: order).each do |sample|
      sample_json = []
      sample_json << sample.name
      if sample.sample_type.present?
        sample_json << sample.sample_type.name
      else
        sample_json << I18n.t("samples.table.no_type")
      end
      if sample.sample_group.present?
        sample_json << sample.sample_group.name
      else
        sample_json << I18n.t("samples.table.no_group")
      end
      sample_json << I18n.l(sample.created_at, format: :full)
      sample_json << sample.user.full_name
      data << sample_json
    end

    # Prepare column headers
    headers = [
      I18n.t("samples.table.sample_name"),
      I18n.t("samples.table.sample_type"),
      I18n.t("samples.table.sample_group"),
      I18n.t("samples.table.added_on"),
      I18n.t("samples.table.added_by")
    ]
    { data: data, headers: headers }
  end

  # Generate the repository rows belonging to this module
  # in JSON form, suitable for display in handsontable.js
  def repository_json_hot(repository_id, order)
    data = []
    repository_rows
      .includes(:created_by)
      .where(repository_id: repository_id)
      .order(created_at: order).find_each do |row|
      row_json = []
      row_json << row.id
      row_json << row.name
      row_json << I18n.l(row.created_at, format: :full)
      row_json << row.created_by.full_name
      data << row_json
    end

    # Prepare column headers
    headers = [
      I18n.t('repositories.table.id'),
      I18n.t('repositories.table.row_name'),
      I18n.t('repositories.table.added_on'),
      I18n.t('repositories.table.added_by')
    ]
    { data: data, headers: headers }
  end

  def repository_json(repository_id, order, user)
    headers = [
      I18n.t('repositories.table.id'),
      I18n.t('repositories.table.row_name'),
      I18n.t('repositories.table.added_on'),
      I18n.t('repositories.table.added_by')
    ]
    repository = Repository.find_by_id(repository_id)
    return false unless repository

    repository.repository_columns.order(:id).each do |column|
      headers.push(column.name)
    end

    params = { assigned: 'assigned', search: {}, order: { values: { column: '1', dir: order } } }
    records = RepositoryDatatableService.new(repository,
                                             params,
                                             user,
                                             self)
    { headers: headers, data: records }
  end

  def repository_docx_json(repository_id)
    headers = [
      I18n.t('repositories.table.id'),
      I18n.t('repositories.table.row_name'),
      I18n.t('repositories.table.added_on'),
      I18n.t('repositories.table.added_by')
    ]
    custom_columns = []
    repository = Repository.find_by(id: repository_id)
    return false unless repository

    repository.repository_columns.order(:id).each do |column|
      headers.push(column.name)
      custom_columns.push(column.id)
    end

    records = repository_rows.where(repository_id: repository_id).select(:id, :name, :created_at, :created_by_id)
    { headers: headers, rows: records, custom_columns: custom_columns }
  end

  def deep_clone(current_user)
    deep_clone_to_experiment(current_user, experiment)
  end

  def deep_clone_to_experiment(current_user, experiment_dest)
    # Copy the module
    clone = MyModule.new(name: name, experiment: experiment_dest, description: description, x: x, y: y)
    # set new position if cloning in the same experiment
    clone.attributes = get_new_position if clone.experiment == experiment

    clone.save!

    # Remove the automatically generated protocol,
    # & clone the protocol instead
    clone.protocol.destroy
    clone.reload

    # Update the cloned protocol if neccesary
    clone_tinymce_assets(clone, clone.experiment.project.team)
    clone.protocols << protocol.deep_clone_my_module(self, current_user)
    clone.reload

    # fixes linked protocols
    clone.protocols.each do |protocol|
      next unless protocol.linked?

      protocol.updated_at = protocol.parent_updated_at
      protocol.save
    end

    clone
  end

  # Find an empty position for the restored module. It's
  # basically a first empty row with empty space inside x=[0, 32).
  def get_new_position
    return { x: 0, y: 0 } if experiment.blank?

    # Get all modules position that overlap with first column, [0, WIDTH) and
    # sort them by y coordinate.
    positions = experiment.active_modules.collect { |m| [m.x, m.y] }
                          .select { |x, _| x >= 0 && x < WIDTH }
                          .sort_by { |_, y| y }
    return { x: 0, y: 0 } if positions.empty? || positions.first[1] >= HEIGHT

    # It looks we'll have to find a gap between the modules if it exists (at
    # least 2*HEIGHT wide
    ind = positions.each_cons(2).map { |f, s| s[1] - f[1] }
                   .index { |y| y >= 2 * HEIGHT }
    return { x: 0, y: positions[ind][1] + HEIGHT } if ind

    # We lucked out, no gaps, therefore we need to add it after the last element
    { x: 0, y: positions.last[1] + HEIGHT }
  end

  def completed?
    state == 'completed'
  end

  # Check if my_module is ready to become completed
  def check_completness_status
    if protocol && protocol.steps.count > 0
      completed = true
      protocol.steps.find_each do |step|
        completed = false unless step.completed
      end
      return true if completed
    end
    false
  end

  def complete
    self.state = 'completed'
    self.completed_on = DateTime.now
  end

  def uncomplete
    self.state = 'uncompleted'
    self.completed_on = nil
  end

  private

  def create_blank_protocol
    protocols << Protocol.new_blank_for_module(self)
  end

  def coordinates_uniqueness_check
    if experiment && experiment.my_modules.active.where(x: x, y: y).where.not(id: id).any?
      errors.add(:position, I18n.t('activerecord.errors.models.my_module.attributes.position.not_unique'))
    end
  end
end
