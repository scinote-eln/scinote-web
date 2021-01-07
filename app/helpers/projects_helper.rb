# frozen_string_literal: true

module ProjectsHelper
  def user_project_role_to_s(user_project)
    t('user_projects.enums.role.' + user_project.role)
  end

  def user_names_with_roles(user_projects)
    user_projects.map { |up| user_name_with_role(up) }.join('&#013;').html_safe
  end

  def user_name_with_role(user_project)
    "#{sanitize_input(user_project.user.name)} - #{I18n.t("user_projects.enums.role.#{user_project.role}")}"
  end

  def construct_module_connections(my_module)
    conns = []
    my_module.outputs.each do |output|
      conns.push(output.to.id)
    end
    conns.to_s[1..-2]
  end

  def sidebar_folders_tree(team, user, sort, view_mode)
    records = if view_mode == 'archived'
                team.projects.archived.visible_to(user, team) +
                  ProjectFolder.archived.inner_folders(team)
              else
                team.projects.active.visible_to(user, team) +
                  ProjectFolder.active.inner_folders(team)
              end
    sort ||= team.current_view_state(user).state.dig('projects', 'active', 'sort')
    records = case sort
              when 'new'
                records.sort_by(&:created_at).reverse!
              when 'old'
                records.sort_by(&:created_at)
              when 'atoz'
                records.sort_by { |c| c.name.downcase }
              when 'ztoa'
                records.sort_by { |c| c.name.downcase }.reverse!
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
