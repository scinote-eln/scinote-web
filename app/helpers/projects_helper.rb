module ProjectsHelper

  def user_project_role_to_s(user_project)
    t("user_projects.enums.role." + user_project.role)
  end

  def construct_module_connections(my_module)
    conns = Array.new
    my_module.outputs.each do |output|
      conns.push(output.to.id)
    end
    conns.to_s[1..-2]
  end

  def last_experiment_updated(project)
    project
      .active_experiments(updated_at: :desc)
      .pluck(:id)
      .first.to_s
  end
end
