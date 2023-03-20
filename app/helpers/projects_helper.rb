# frozen_string_literal: true

module ProjectsHelper
  def projects_view_mode(project: nil)
    return (project.archived? ? 'archived' : 'active') if project

    return 'archived' if current_folder&.archived?

    params[:view_mode] == 'archived' ? 'archived' : 'active'
  end

  def projects_view_mode_archived?
    projects_view_mode == 'archived'
  end

  def user_names_with_roles(user_assignments)
    names_with_roles = user_assignments.map { |up| user_name_with_role(up) }.join('&#013;')
    sanitize_input(names_with_roles)
  end

  def user_name_with_role(user_assignment)
    "#{escape_input(user_assignment.user.name)} - #{escape_input(user_assignment.user_role.name)}"
  end

  def construct_module_connections(my_module)
    conns = []
    my_module.outputs.each do |output|
      conns.push(output.to.id)
    end
    conns.to_s[1..-2]
  end

  def sidebar_folders_tree(team, user, sort, folders_only: false)
    sort ||= team.current_view_state(user).state.dig('projects', 'active', 'sort')
    if projects_view_mode_archived?
      records = ProjectFolder.archived.inner_folders(team)
      records += team.projects.archived.visible_to(user, team) unless folders_only
    else
      records = ProjectFolder.active.inner_folders(team)
      records += team.projects.active.visible_to(user, team) unless folders_only
      sort = 'new' if %w(archived_old archived_new).include?(sort)
    end
    records = case sort
              when 'new'
                records.sort_by(&:created_at).reverse!
              when 'old'
                records.sort_by(&:created_at)
              when 'atoz'
                records.sort_by { |c| c.name.downcase }
              when 'ztoa'
                records.sort_by { |c| c.name.downcase }.reverse!
              when 'id_asc'
                records.sort_by(&:id)
              when 'id_desc'
                records.sort_by(&:id).reverse!
              when 'archived_old'
                records.sort_by(&:archived_on)
              when 'archived_new'
                records.sort_by(&:archived_on).reverse!
              end
    folders_recursive_builder(nil, records)
  end

  private

  def folders_recursive_builder(folder, records)
    children = records.select do |i|
      (defined?(i.parent_folder_id) && i.parent_folder_id == folder&.id) ||
        (defined?(i.project_folder_id) && i.project_folder_id == folder&.id)
    end

    children.map do |i|
      if i.class == Project
        { project: i }
      else
        {
          folder: i,
          children: folders_recursive_builder(i, records)
        }
      end
    end
  end
end
