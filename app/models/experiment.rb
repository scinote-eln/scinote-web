# frozen_string_literal: true

class Experiment < ApplicationRecord
  ID_PREFIX = 'EX'

  include PrefixedIdModel
  SEARCHABLE_ATTRIBUTES = [:name, :description, PREFIXED_ID_SQL].freeze

  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel
  include PermissionCheckableModel
  include Assignable

  before_save -> { report_elements.destroy_all }, if: -> { !new_record? && project_id_changed? }

  belongs_to :project, inverse_of: :experiments, touch: true
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User'
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User'
  belongs_to :archived_by,
             foreign_key: :archived_by_id, class_name: 'User', optional: true
  belongs_to :restored_by,
             foreign_key: :restored_by_id,
             class_name: 'User',
             optional: true

  has_many :my_modules, inverse_of: :experiment, dependent: :destroy
  has_many :my_module_groups, inverse_of: :experiment, dependent: :destroy
  has_many :report_elements, inverse_of: :experiment, dependent: :destroy
  # Associations for old activity type
  has_many :activities, inverse_of: :experiment
  has_many :users, through: :user_assignments

  has_one_attached :workflowimg

  auto_strip_attributes :name, :description, nullify: false
  validates :name, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :project, presence: true
  validates :created_by, presence: true
  validates :last_modified_by, presence: true
  validates :uuid, uniqueness: { scope: :project },
                   unless: proc { |e| e.uuid.blank? }

  scope :is_archived, lambda { |is_archived|
    if is_archived
      joins(:project).where('experiments.archived = TRUE OR projects.archived = TRUE')
    else
      joins(:project).where('experiments.archived = FALSE AND projects.archived = FALSE')
    end
  }

  scope :experiment_search_scope, lambda { |project_ids, user|
    joins(:user_assignments).where(
      project: project_ids,
      user_assignments: { user: user }
    )
  }

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    current_team = nil,
    options = {}
  )
    experiment_scope = experiment_search_scope(
      Project
        .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
        .pluck(:id),
      user
    )

    if current_team
      new_query = experiment_search_scope(
        Project.search(
          user,
          include_archived,
          nil,
          1,
          current_team
        ).select('id'),
        user
      ).where_attributes_like(SEARCHABLE_ATTRIBUTES, query, options)
      return include_archived ? new_query : new_query.active
    elsif include_archived
      new_query = experiment_scope.where_attributes_like(SEARCHABLE_ATTRIBUTES, query, options)
    else
      new_query = experiment_scope.active
                                  .where_attributes_like(SEARCHABLE_ATTRIBUTES, query, options)
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
    left_outer_joins(user_assignments: :user_role)
      .where(project: Project.viewable_by_user(user, teams))
      .where(user_assignments: { user: user })
      .where('user_roles.permissions @> ARRAY[?]::varchar[]', %w[experiment_read])
  end

  def archived_branch?
    archived? || project.archived?
  end

  def navigable?
    !project.archived?
  end

  def update_canvas(
    to_archive,
    to_add,
    to_rename,
    to_move,
    to_move_groups,
    to_clone,
    connections,
    positions,
    current_user
  )
    begin
      with_lock do
        # Start with archiving to release positions for new tasks
        archive_modules(to_archive, current_user) if to_archive.any?

        # Update only existing tasks positions to release positions for new tasks
        existing_positions = positions.slice(*positions.keys.map { |k| k unless k.to_s.start_with?('n') }.compact)
        update_module_positions(existing_positions) if existing_positions.any?

        # Move only existing tasks to release positions for new tasks
        existing_to_move = to_move.slice(*to_move.keys.map { |k| k unless k.to_s.start_with?('n') }.compact)
        move_modules(existing_to_move, current_user) if existing_to_move.any?

        # add new modules
        new_ids, cloned_pairs, originals = add_modules(
          to_add, to_clone, current_user
        )

        # Rename modules
        rename_modules(to_rename, current_user)

        # Add activities that modules were created
        originals.each do |my_module|
          log_activity(:create_module, current_user, my_module)
        end

        # Add activities that modules were cloned
        cloned_pairs.each do |mn, mo|
          Activities::CreateActivityService
            .call(activity_type: :clone_module,
                  owner: current_user,
                  team: project.team,
                  project: mn.experiment.project,
                  subject: mn,
                  message_items: { my_module_original: mo.id,
                                   my_module_new: mn.id })
        end

        # Update connections, positions & module group variables
        # with actual IDs retrieved from the new modules creation
        updated_to_move = {}
        to_move.each do |id, value|
          updated_to_move[new_ids.fetch(id, id)] = value
        end
        updated_to_move_groups = {}
        to_move_groups.each do |ids, value|
          mapped = []
          ids.each do |id|
            mapped << new_ids.fetch(id, id)
          end
          updated_to_move_groups[mapped] = value
        end
        updated_connections = []
        connections.each do |a, b|
          updated_connections << [new_ids.fetch(a, a), new_ids.fetch(b, b)]
        end
        updated_positions = {}
        positions.each do |id, pos|
          updated_positions[new_ids.fetch(id, id)] = pos
        end

        # Update connections
        update_module_connections(updated_connections)

        # Update module positions (no validation needed here)
        update_module_positions(updated_positions)

        # Normalize module positions
        normalize_module_positions

        # Finally, update module groups
        update_module_groups(current_user)

        # Finally move any modules to another experiment
        move_modules(updated_to_move, current_user)

        # Everyhing is set, now we can move any module groups
        move_module_groups(updated_to_move_groups, current_user)
      end
    rescue ActiveRecord::ActiveRecordError,
           ArgumentError,
           ActiveRecord::RecordNotSaved => ex
      logger.error ex.message
      return false
    end
    true
  end

  def workflowimg_exists?
    workflowimg.attached? && workflowimg.service.exist?(workflowimg.blob.key)
  end

  # Get projects where user is either owner or user in the same team
  # as this experiment
  def projects_with_role_above_user(current_user)
    team = project.team
    projects = team.projects.where(archived: false)

    current_user.user_projects
                .where(project: projects)
                .where('role < 2')
                .map(&:project)
  end

  # Projects to which this experiment can be moved (inside the same
  # team and not archived), all users assigned on experiment.project has
  # to be assigned on such project
  def movable_projects(current_user)
    viewer_role = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer'))
    current_user.projects.where.not(id: project_id).where(archived: false, team: project.team).select do |p|
      can_create_project_experiments?(current_user, p) &&
        project.user_assignments.where.not(user_role: viewer_role).pluck(:user_id) ==
          p.user_assignments.where.not(user_role: viewer_role).pluck(:user_id)
    end
  end

  def permission_parent
    project
  end

  private

  # Archive all modules. Receives an array of module integer IDs
  # and current user.
  def archive_modules(module_ids, current_user)
    my_modules.where(id: module_ids).each do |my_module|
      my_module.archive!(current_user)
      log_activity(:archive_module, current_user, my_module)
    end
    my_modules.reload
  end

  # Add modules, and returns a map of "virtual" IDs with
  # actual IDs of saved modules.
  # to_add is an array of hashes, each containing 'name',
  # 'x', 'y' and 'id'.
  # to_clone is a hash, storing new cloned modules as keys,
  # and original modules as values.
  def add_modules(to_add, to_clone, current_user)
    originals = []
    cloned_pairs = {}
    ids_map = {}
    to_add.each do |m|
      original = MyModule.find_by(id: to_clone.fetch(m[:id], nil)) if to_clone.present?
      if original.present?
        my_module = original.deep_clone(current_user)
        cloned_pairs[my_module] = original
      else
        my_module = MyModule.new(experiment: self)
        originals << my_module
      end

      my_module.name = m[:name]
      my_module.x = m[:x]
      my_module.y = m[:y]
      my_module.created_by = current_user
      my_module.last_modified_by = current_user
      my_module.save!

      my_module.assign_user(current_user)

      ids_map[m[:id]] = my_module.id.to_s
    end
    my_modules.reload
    return ids_map, cloned_pairs, originals
  end

  # Rename modules; this method accepts a map where keys
  # represent IDs of modules, and values new names for
  # such modules. If a module with given ID doesn't exist,
  # it's obviously not updated.
  def rename_modules(to_rename, current_user)
    to_rename.each do |id, new_name|
      my_module = MyModule.find_by_id(id)
      if my_module.present?
        my_module.name = new_name
        my_module.save!
        log_activity(:rename_task, current_user, my_module)
      end
    end
  end

  # Move modules; this method accepts a map where keys
  # represent IDs of modules, and values represent experiment
  # IDs of new names to which the given modules should be moved.
  # If a module with given ID doesn't exist (or experiment ID)
  # it's obviously not updated. Any connection on module is destroyed.
  def move_modules(to_move, current_user)
    to_move.each do |id, experiment_id|
      my_module = my_modules.find_by_id(id)
      experiment = project.experiments.find_by_id(experiment_id)
      next unless my_module.present? && experiment.present?

      experiment_original = my_module.experiment
      my_module.experiment = experiment

      # Calculate new module position
      new_pos = my_module.get_new_position
      my_module.x = new_pos[:x]
      my_module.y = new_pos[:y]

      unless my_module.outputs.destroy_all && my_module.inputs.destroy_all
        raise ActiveRecord::ActiveRecordError
      end

      next unless my_module.save
      # regenerate user assignments
      my_module.user_assignments.destroy_all
      UserAssignments::GenerateUserAssignmentsJob.perform_later(my_module, current_user)

      Activities::CreateActivityService.call(activity_type: :move_task,
                                             owner: current_user,
                                             subject: my_module,
                                             project: project,
                                             team: project.team,
                                             message_items: {
                                               my_module: my_module.id,
                                               experiment_original:
                                                 experiment_original.id,
                                               experiment_new: experiment.id
                                             })
    end
  end

  # Move module groups; this method accepts a map where keys
  # represent IDs of modules which are in module group,
  # and values represent experiment
  # IDs of new names to which the given module group should be moved.
  # If a module with given ID doesn't exist (or experiment ID)
  # it's obviously not updated. Position for entire module group is updated
  # to bottom left corner.
  def move_module_groups(to_move, current_user)
    to_move.each do |ids, experiment_id|
      modules = my_modules.find(ids)
      groups = Set.new(modules.map(&:my_module_group))
      experiment = project.experiments.find_by_id(experiment_id)

      groups.each do |group|
        next unless group && experiment.present?

        # Find the lowest point for current modules(max_y) and the leftmost
        # module(min_x)
        active_modules = experiment.my_modules.active
        if active_modules.blank?
          max_y = 0
          min_x = 0
        else
          max_y = active_modules.maximum(:y) + MyModule::HEIGHT
          min_x = active_modules.minimum(:x)
        end

        # Set new positions
        curr_min_x = modules.min_by(&:x).x
        curr_min_y = modules.min_by(&:y).y
        modules.each { |m| m.x += -curr_min_x + min_x }
        modules.each { |m| m.y += -curr_min_y + max_y }

        modules.each do |m|
          experiment_org = m.experiment
          m.experiment = experiment
          m.save!

          # Add activity
          Activities::CreateActivityService.call(
            activity_type: :move_task,
            owner: current_user,
            subject: m,
            project: experiment.project,
            team: experiment.project.team,
            message_items: {
              my_module: m.id,
              experiment_original: experiment_org.id,
              experiment_new: experiment.id
            }
          )
        end

        group.experiment = experiment
        group.save!
      end
    end
  end

  # Update connections for all modules in this project.
  # Input is an array of arrays, where first element represents
  # source node, and second element represents target node.
  # Example input: [ [1, 2], [2, 3], [4, 5], [2, 5] ]
  def update_module_connections(connections)
    require 'rgl/base'
    require 'rgl/adjacency'
    require 'rgl/topsort'
    dg = RGL::DirectedAdjacencyGraph.new
    connections.each do |a, b|
      # Check if both vertices exist
      if (my_modules.find_all { |m| [a.to_i, b.to_i].include? m.id }).count == 2
        dg.add_edge(a, b)
      end
    end

    # Check if cycles exist!
    topsort = dg.topsort_iterator.to_a
    if topsort.length.zero? && dg.edges.size > 1
      raise ArgumentError, 'Cycles exist.'
    end

    # First, delete existing connections
    # but keep a copy of previous state
    previous_sources = {}
    previous_sources.default = []

    my_modules.includes(inputs: { from: [:inputs, outputs: :to] }).each do |m|
      previous_sources[m.id] = []
      m.inputs.each do |c|
        previous_sources[m.id] << c.from
      end
    end

    # There are no callbacks in Connection, so delete_all should be safe
    Connection.where(output_id: my_modules).delete_all

    # Add new connections
    filtered_edges = dg.edges.collect { |e| [e.source, e.target] }
    filtered_edges.each do |a, b|
      Connection.create!(input_id: b, output_id: a)
    end

    # Save topological order of modules (for modules without workflow,
    # leave them unordered)
    my_modules.includes(:my_module_group).each do |m|
      m.workflow_order =
        if topsort.include? m.id.to_s
          topsort.find_index(m.id.to_s)
        else
          -1
        end
      m.save!
    end

    # Make sure to reload my modules, which now have updated connections
    my_modules.reload
    true
  end

  # Updates positions of modules.
  # Input is a map where keys are module IDs, and values are
  # hashes like { x: <x>, y: <y> }.
  def update_module_positions(positions)
    modules = my_modules.where(id: positions.keys)
    modules.each do |m|
      m.update(x: positions[m.id.to_s][:x], y: positions[m.id.to_s][:y])
    end
    my_modules.reload
  end

  # Normalize module positions in this project.
  def normalize_module_positions
    # This method normalizes module positions so x-s and y-s
    # are all positive
    x_diff = my_modules.active.pluck(:x).min
    y_diff = my_modules.active.pluck(:y).min

    return unless x_diff && y_diff

    moving_direction = {
      x: x_diff.positive? ? :asc : :desc,
      y: y_diff.positive? ? :asc : :desc
    }
    my_modules.active.order(moving_direction).each do |m|
      m.update!(x: m.x - x_diff, y: m.y - y_diff)
    end
    my_modules.reload
  end

  # Recalculate module groups in this project. Input is
  # a hash of module ids and their corresponding module names.
  def update_module_groups(current_user)
    require 'rgl/base'
    require 'rgl/adjacency'
    require 'rgl/connected_components'

    dg = RGL::DirectedAdjacencyGraph[]
    group_ids = Set.new
    my_modules.active.includes(:my_module_group, outputs: :to).each do |m|
      group_ids << m.my_module_group.id unless m.my_module_group.blank?
      dg.add_vertex m.id unless dg.has_vertex? m.id
      m.outputs.each do |o|
        dg.add_edge m.id, o.to.id
      end
    end
    workflows = []
    dg.to_undirected.each_connected_component do |w|
      workflows << my_modules.find(w)
    end

    # Remove any existing module groups from modules
    unless MyModuleGroup.where(id: group_ids.to_a).destroy_all
      raise ActiveRecord::ActiveRecordError
    end

    # Second, create new groups
    workflows.each do |modules|
      # Single modules are not considered part of any workflow
      next unless modules.length > 1
      MyModuleGroup.create!(experiment: self,
                            my_modules: modules,
                            created_by: current_user)
    end

    my_module_groups.reload
    true
  end

  def log_activity(type_of, current_user, my_module)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: my_module.experiment.project.team,
            project: my_module.experiment.project,
            subject: my_module,
            message_items: { my_module: my_module.id })
  end
end
