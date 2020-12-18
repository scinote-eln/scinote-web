# frozen_string_literal: true

module ProjectsHelper
  def user_project_role_to_s(user_project)
    t('user_projects.enums.role.' + user_project.role)
  end

  def construct_module_connections(my_module)
    conns = []
    my_module.outputs.each do |output|
      conns.push(output.to.id)
    end
    conns.to_s[1..-2]
  end

  def sidebar_folders_tree(team, user)
    records = user.projects_tree(team) + ProjectFolder.inner_folders(team)
    view_state = team.current_view_state(user)
    records = case view_state.state.dig('projects', 'active', 'sort')
              when 'new'
                records.sort_by(&:created_at).reverse!
              when 'old'
                records.sort_by(&:created_at)
              when 'atoz'
                records.sort_by { |c| c.name.downcase }
              when 'ztoa'
                records.sort_by { |c| c.name.downcase }.reverse!
              when 'arch_old'
                records.sort_by(&:archived_on)
              when 'arch_new'
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
