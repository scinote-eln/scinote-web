# frozen_string_literal: true

module GlobalActivitiesHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include InputSanitizeHelper

  def generate_activity_content(activity)
    parameters = {}
    activity.values[:parameters].each do |key, value|
      parameters[key] =
        if value.is_a? String
          value
        else
          public_send("activity_#{value[:type].underscore}_link",
                      value[:id],
                      value[:name])
        end
    end
    I18n.t("activities.content.#{activity.type_of}_html", parameters)
  end

  def team_link(id, name)
    team = Team.find_by_id(id)
    return name unless team
    route_to_other_team projects_path(team: team), team, team.name
  end

  def activity_project_link(id, name)
    project = Project.find_by_id(id)
    return name unless project
    link_to project.name, project_path(project)
  end

  def activity_experiment_link(id, name)
    experiment = Experiment.find_by_id(id)
    return name unless experiment
    link_to experiment.name, canvas_experiment_path(experiment)
  end

  def activity_my_module_link(id, name)
    task = MyModule.find_by_id(id)
    return name unless task
    link_to experiment.name, protocols_my_module_path(task)
  end

  def activity_protocol_link(id, name)
    protocol = Protocol.find_by_id(id)
    return name unless protocol
    if protocol.in_repository?
      route_to_other_team protocols_path, protocol.team, protocol.name
    else
      link_to protocol.name, protocols_my_module_path(protocol.my_module)
    end
  end

  def activity_result_link(id, name)
    result = Result.find_by_id(id)
    return name unless result
    link_to result.name, results_my_module_path(result.my_module)
  end

  def activity_inventory_link(id, name)
    inventory = Repository.find_by_id(id)
    return name unless inventory
    link_to inventory.name, repository_path(inventory)
  end

  def activity_inventory_item_link(id, name)
    item = RepositoryRow.find_by_id(id)
    return name unless item
    link_to item.name, repository_path(item.repository)
  end
end
