# frozen_string_literal: true

module ExperimentsHelper
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
  def experiments_view_mode(project)
    return 'archived' if project.archived?

    params[:view_mode] == 'archived' ? 'archived' : 'active'
  end

<<<<<<< HEAD
=======
>>>>>>> Pulled latest release
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
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
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.

  def experiment_archived_on(experiment)
    if experiment.archived?
      experiment.archived_on
    elsif experiment.project.archived?
      experiment.project.archived_on
    end
  end
<<<<<<< HEAD
=======
>>>>>>> Pulled latest release
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
end
