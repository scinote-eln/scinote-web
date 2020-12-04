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

  def sidebar_folders_tree(team)
    records = team.projects + ProjectFolder.inner_folders(team)
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
