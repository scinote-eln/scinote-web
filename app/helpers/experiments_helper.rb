# frozen_string_literal: true

module ExperimentsHelper
  def grouped_by_prj(experiments)
    ungrouped_experiments = experiments.joins(:project)
                                       .select('projects.name as project_name,
                                         projects.archived as project_archived,
                                         experiments.*')
    ungrouped_experiments.group_by { |i| [i[:project_name]] }.map do |group, exps|
      {
        project_name: group[0],
        project_archived: exps[0]&.project_archived,
        experiments: exps
      }
    end
  end
end
