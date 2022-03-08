class Experiment < ApplicationRecord
  include ArchivableModel
  include SearchableModel

  belongs_to :project, inverse_of: :experiments, optional: true
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User',
             optional: true
  belongs_to :archived_by,
             foreign_key: :archived_by_id, class_name: 'User', optional: true
  belongs_to :restored_by,
             foreign_key: :restored_by_id,
             class_name: 'User',
             optional: true

  has_many :my_modules, inverse_of: :experiment, dependent: :destroy
  has_many :active_my_modules, -> { where(archived: false) },
           class_name: 'MyModule'
  has_many :my_module_groups, inverse_of: :experiment, dependent: :destroy
  has_many :report_elements, inverse_of: :experiment, dependent: :destroy
  has_many :activities, inverse_of: :experiment

  has_attached_file :workflowimg
  validates_attachment :workflowimg,
                       content_type: { content_type: ['image/png'] },
                       if: :workflowimg_check

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :project, case_sensitive: false }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :project, presence: true
  validates :created_by, presence: true
  validates :last_modified_by, presence: true
  with_options if: :archived do |experiment|
    experiment.validates :archived_by, presence: true
    experiment.validates :archived_on, presence: true
  end

  scope :is_archived, ->(is_archived) { where("archived = ?", is_archived) }

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    current_team = nil,
    options = {}
  )
    project_ids =
      Project
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    if current_team
      projects_ids =
        Project
        .search(user,
                include_archived,
                nil,
                1,
                current_team)
        .select('id')

      new_query =
        Experiment
        .where('experiments.project_id IN (?)', projects_ids)
        .where_attributes_like([:name, :description], query, options)
      return include_archived ? new_query : new_query.is_archived(false)
    elsif include_archived
      new_query =
        Experiment
        .where(project: project_ids)
        .where_attributes_like([:name, :description], query, options)
    else
      new_query =
        Experiment
        .is_archived(false)
        .where(project: project_ids)
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

  def modules_without_group
    MyModule.where(experiment_id: id)
            .where(my_module_group: nil)
            .where(archived: false)
  end

  def active_module_groups
    my_module_groups.joins(:my_modules)
                    .where('my_modules.archived = ?', false)
                    .distinct
  end

  def active_modules
    my_modules.where(archived: false)
  end

  def archived_modules
    my_modules.where(archived: true)
  end

  def assigned_samples
    Sample.joins(:my_modules).where(my_modules: { id: my_modules })
  end

  def unassigned_samples(assigned_samples)
    Sample.where(team_id: team).where.not(id: assigned_samples)
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
    cloned_modules = []
    begin
      with_lock do
        # First, add new modules
        new_ids, cloned_pairs, originals = add_modules(
          to_add, to_clone, current_user
        )
        cloned_modules = cloned_pairs.collect { |mn, _| mn }

        # Rename modules
        rename_modules(to_rename)

        # Add activities that modules were created
        originals.each do |m|
          Activity.create(type_of: :create_module,
            user: current_user,
            project: project,
            experiment: m.experiment,
            my_module: m,
            message: I18n.t('activities.create_module',
                            user: current_user.full_name,
                            module: m.name))
        end

        # Add activities that modules were cloned
        cloned_pairs.each do |mn, mo|
          Activity.create(type_of: :clone_module,
            project: mn.experiment.project,
            experiment: mn.experiment,
            my_module: mn,
            user: current_user,
            message: I18n.t('activities.clone_module',
                            user: current_user.full_name,
                            module_new: mn.name,
                            module_original: mo.name))
        end

        # Then, archive modules that need to be archived
        archive_modules(to_archive, current_user) if to_archive.any?

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
        move_modules(updated_to_move)

        # Everyhing is set, now we can move any module groups
        move_module_groups(updated_to_move_groups)
      end
    rescue ActiveRecord::ActiveRecordError,
           ArgumentError,
           ActiveRecord::RecordNotSaved => ex
      logger.error ex.message
      return false
    end
    true
  end

  # This method generate the workflow image and saves it as
  # experiment attachment
  def generate_workflow_img
    require 'graphviz'

    graph = GraphViz.new(:G,
                         type: :digraph,
                         use: :neato)

    graph[:size] = '4,4'
    graph.node[color: Constants::COLOR_ALTO,
               style: :filled,
               fontcolor: Constants::COLOR_EMPEROR,
               shape: 'circle',
               fontname: 'Arial',
               fontsize: '16.0']

    graph.edge[color: Constants::COLOR_ALTO]

    label = ''
    subg = {}

    # Draw orphan modules
    if modules_without_group
      modules_without_group.each do |my_module|
        graph
          .subgraph(rank: 'same')
          .add_nodes("Orphan-#{my_module.id}",
                     label: label,
                     pos: "#{my_module.x / 10},-#{my_module.y / 10}!")
      end
    end

    # Draw grouped modules
    if my_module_groups.many?
      my_module_groups.each_with_index do |group, gindex|
        subgraph_name = "cluster-#{gindex}"
        subg[subgraph_name] = graph.subgraph(rank: 'same')
        group.ordered_modules.each_with_index do |my_module, index|
          if my_module.outputs.any?
            parent = subg[subgraph_name]
                     .add_nodes("#{subgraph_name}-#{index}",
                                label: label,
                                pos: "#{my_module.x / 10},-#{my_module.y / 10}!")

            my_module.outputs.each_with_index do |output, i|
              child_mod = MyModule.find_by_id(output.input_id)
              child_node = subg[subgraph_name]
                           .add_nodes("#{subgraph_name}-O#{child_mod.id}-#{i}",
                                      label: label,
                                      pos: "#{child_mod.x / 10},-#{child_mod.y / 10}!")

              subg[subgraph_name].add_edges(parent, child_node)
            end
          elsif my_module.inputs.any?
            parent = subg[subgraph_name]
                     .add_nodes("#{subgraph_name}-#{index}",
                                label: label,
                                pos: "#{my_module.x / 10},-#{my_module.y / 10}!")

            my_module.inputs.each_with_index do |input, i|
              child_mod = MyModule.find_by_id(input.output_id)
              child_node = subg[subgraph_name]
                           .add_nodes("#{subgraph_name}-I#{child_mod.id}-#{i}",
                                      label: label,
                                      pos: "#{child_mod.x / 10},-#{child_mod.y / 10}!")

              subg[subgraph_name].add_edges(child_node, parent)
            end
          end
        end
      end
    else
      my_module_groups.each do |group|
        group.ordered_modules.each_with_index do |my_module, index|
          if my_module.outputs.any?
            parent = graph.add_nodes("N-#{index}",
                                     label: label,
                                     pos: "#{my_module.x / 10},-#{ my_module.y / 10}!")

            my_module.outputs.each_with_index do |output, i|
              child_mod = MyModule.find_by_id(output.input_id)
              child_node = graph
                           .add_nodes("N-O#{child_mod.id}-#{i}",
                                      label: label,
                                      pos: "#{child_mod.x / 10},-#{child_mod.y / 10}!")
              graph.add_edges(parent, child_node)
            end
          elsif my_module.inputs.any?
            parent = graph.add_nodes("N-#{index}",
                                     label: label,
                                     pos: "#{my_module.x / 10},-#{my_module.y / 10}!")
            my_module.inputs.each_with_index do |input, i|
              child_mod = MyModule.find_by_id(input.output_id)
              child_node = graph
                           .add_nodes("N-I#{child_mod.id}-#{i}",
                                      label: label,
                                      pos: "#{child_mod.x / 10},-#{child_mod.y / 10}!")
              graph.add_edges(child_node, parent)
            end
          end
        end
      end
    end

    file_location = Tempfile.open(['wimg', '.png'],
                                  Rails.root.join('tmp'))

    graph.output(png: file_location.path)

    begin
      file = File.open(file_location)
      self.workflowimg = file
      file.close
      save
      touch(:workflowimg_updated_at)
    rescue => ex
      logger.error ex.message
    end
  end

  # Clone this experiment to given project
  def deep_clone_to_project(current_user, project)
    # First we have to find unique name for our little experiment
    experiment_names = project.experiments.map(&:name)
    format = 'Clone %d - %s'

    i = 1
    i += 1 while experiment_names.include?(format(format, i, name))

    clone = Experiment.new(
      name: format(format, i, name).truncate(Constants::NAME_MAX_LENGTH),
      description: description,
      created_by: current_user,
      last_modified_by: current_user,
      project: project
    )

    # Copy all workflows
    my_module_groups.each do |g|
      clone.my_module_groups << g.deep_clone_to_experiment(current_user, clone)
    end

    # Copy modules without group
    clone.my_modules << modules_without_group.map do |m|
      m.deep_clone_to_experiment(current_user, clone)
    end
    clone.save
    clone
  end

  def move_to_project(project)
    self.project = project

    my_modules.each do |m|
      new_tags = []
      m.tags.each do |t|
        new_tags << t.deep_clone_to_project(project)
      end
      m.my_module_tags.destroy_all

      project.tags << new_tags
      m.tags << new_tags
    end
    result = save
    touch(:workflowimg_updated_at) if result
    result
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
  def moveable_projects(current_user)
    projects = projects_with_role_above_user(current_user)

    projects = projects.each_with_object([]) do |p, arr|
      arr << p if (project.users - p.users).empty?
      arr
    end
    projects - [project]
  end

  private

  # Archive all modules. Receives an array of module integer IDs.
  def archive_modules(module_ids)
    my_modules.where(id: module_ids).each(&:archive!)
    my_modules.reload
  end

  # Archive all modules. Receives an array of module integer IDs
  # and current user.
  def archive_modules(module_ids, current_user)
    my_modules.where(id: module_ids).each do |m|
      m.archive!(current_user)
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
      original = MyModule.find_by_id(to_clone.fetch(m[:id], nil))
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

      ids_map[m[:id]] = my_module.id.to_s
    end
    my_modules.reload
    return ids_map, cloned_pairs, originals
  end

  # Rename modules; this method accepts a map where keys
  # represent IDs of modules, and values new names for
  # such modules. If a module with given ID doesn't exist,
  # it's obviously not updated.
  def rename_modules(to_rename)
    to_rename.each do |id, new_name|
      my_module = MyModule.find_by_id(id)
      if my_module.present?
        my_module.name = new_name
        my_module.save!
      end
    end
  end

  # Move modules; this method accepts a map where keys
  # represent IDs of modules, and values represent experiment
  # IDs of new names to which the given modules should be moved.
  # If a module with given ID doesn't exist (or experiment ID)
  # it's obviously not updated. Any connection on module is destroyed.
  def move_modules(to_move)
    to_move.each do |id, experiment_id|
      my_module = my_modules.find_by_id(id)
      experiment = project.experiments.find_by_id(experiment_id)
      next unless my_module.present? && experiment.present?

      my_module.experiment = experiment

      # Calculate new module position
      new_pos = my_module.get_new_position
      my_module.x = new_pos[:x]
      my_module.y = new_pos[:y]

      unless my_module.outputs.destroy_all && my_module.inputs.destroy_all
        raise ActiveRecord::ActiveRecordError
      end

      my_module.save
    end

    # Generate workflow image for the experiment in which we moved the task
    generate_workflow_img_for_moved_modules(to_move)
  end

  # Move module groups; this method accepts a map where keys
  # represent IDs of modules which are in module group,
  # and values represent experiment
  # IDs of new names to which the given module group should be moved.
  # If a module with given ID doesn't exist (or experiment ID)
  # it's obviously not updated. Position for entire module group is updated
  # to bottom left corner.
  def move_module_groups(to_move)
    to_move.each do |ids, experiment_id|
      modules = my_modules.find(ids)
      groups = Set.new(modules.map(&:my_module_group))
      experiment = project.experiments.find_by_id(experiment_id)

      groups.each do |group|
        next unless group && experiment.present?

        # Find the lowest point for current modules(max_y) and the leftmost
        # module(min_x)
        if experiment.active_modules.empty?
          max_y = 0
          min_x = 0
        else
          max_y = experiment.active_modules.maximum(:y) + MyModule::HEIGHT
          min_x = experiment.active_modules.minimum(:x)
        end

        # Set new positions
        curr_min_x = modules.min_by(&:x).x
        curr_min_y = modules.min_by(&:y).y
        modules.each { |m| m.x += -curr_min_x + min_x }
        modules.each { |m| m.y += -curr_min_y + max_y }

        modules.each do |m|
          m.experiment = experiment
          m.save!
        end

        group.experiment = experiment
        group.save!
      end
    end

    # Generate workflow image for the experiment in which we moved the workflow
    generate_workflow_img_for_moved_modules(to_move)
  end

  # Generates workflow img when the workflow or module is moved
  # to other experiment
  def generate_workflow_img_for_moved_modules(to_move)
    Experiment.where(id: to_move.values.uniq).each do |exp|
      exp.delay.generate_workflow_img
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

    # Unassign samples from former downstream modules
    # for all destroyed connections
    unassign_samples_from_old_downstream_modules(previous_sources)

    visited = []
    # Assign samples to all new downstream modules
    filtered_edges.each do |a, b|
      source = my_modules.includes({ inputs: :from }, :samples).find(a.to_i)
      target = my_modules.find(b.to_i)
      # Do this only for new edges
      next unless previous_sources[target.id].exclude?(source)
      # Go as high upstream as new edges take us
      # and then assign samples to all downsteam samples
      assign_samples_to_new_downstream_modules(previous_sources,
                                               visited,
                                               source)
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
    # and samples
    my_modules.reload
    true
  end

  # When connections are deleted, unassign samples that
  # are not inherited anymore
  def unassign_samples_from_old_downstream_modules(sources)
    my_modules.each do |my_module|
      sources[my_module.id].each do |src|
        # Only do this for newly deleted connections
        next unless src.outputs.map(&:to).exclude? my_module
        my_module.downstream_modules.each do |dm|
          # Get unique samples for all upstream modules
          um = dm.upstream_modules
          um.shift # remove current module
          ums = um.map(&:samples).flatten.uniq
          src.samples.find_each do |sample|
            dm.samples.destroy(sample) if ums.exclude? sample
          end
        end
      end
    end
  end

  # Assign samples to new connections recursively
  def assign_samples_to_new_downstream_modules(sources, visited, my_module)
    # If samples are already assigned for this module, stop going upstream
    return if visited.include?(my_module)
    visited << my_module
    # Edge case, when module is source or it doesn't have any new input
    # connections
    if my_module.inputs.blank? ||
       (my_module.inputs.map(&:from) - sources[my_module.id]).empty?
      my_module.downstream_modules.each do |dm|
        new_samples = my_module.samples.where.not(id: dm.samples)
        dm.samples << new_samples
      end
    else
      my_module.inputs.each do |input|
        # Go upstream for new in connections
        if sources[my_module.id].exclude?(input.from)
          assign_samples_to_new_downstream_modules(sources, visited, input.from)
        end
      end
    end
  end

  # Updates positions of modules.
  # Input is a map where keys are module IDs, and values are
  # hashes like { x: <x>, y: <y> }.
  def update_module_positions(positions)
    modules = my_modules.where(id: positions.keys)
    modules.each do |m|
      m.update_columns(x: positions[m.id.to_s][:x], y: positions[m.id.to_s][:y])
    end
    my_modules.reload
  end

  # Normalize module positions in this project.
  def normalize_module_positions
    # This method normalizes module positions so x-s and y-s
    # are all positive
    x_diff = my_modules.pluck(:x).min
    y_diff = my_modules.pluck(:y).min

    my_modules.each do |m|
      m.update_columns(x: m.x - x_diff, y: m.y - y_diff)
    end
  end

  # Recalculate module groups in this project. Input is
  # a hash of module ids and their corresponding module names.
  def update_module_groups(current_user)
    require 'rgl/base'
    require 'rgl/adjacency'
    require 'rgl/connected_components'

    dg = RGL::DirectedAdjacencyGraph[]
    group_ids = Set.new
    active_modules.includes(:my_module_group, outputs: :to).each do |m|
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

  def workflowimg_check
    workflowimg_content_type
  rescue
    false
  end
end
