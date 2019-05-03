# frozen_string_literal: true

json.draw @draw
json.recordsTotal @projects.total_count
json.recordsFiltered @projects.total_count
json.data do
  json.array! @projects do |project|
    json.set! 'DT_RowId', project.id
    json.set! 'DT_RowClass', project.archived ? 'archived' : ''
    json.set! 'status', if project.archived
                          '<i class="fas fa-archive"></i>' +
                          I18n.t('projects.index.archived')
                        else
                          '<i class="fas fa-arrow-alt-circle-right"></i>' +
                          I18n.t('projects.index.active')
                        end
    json.set! 'name', if project.archived
                        escape_input(project.name)
                      else
                        link_to(escape_input(project.name),
                                project_path(project),
                                class: 'active-project-link')
                      end
    json.set! 'start', I18n.l(project.created_at, format: :full)
    json.set! 'visibility', if project.visibility == 'hidden'
                              '<i class="fas fa-eye-slash"></i>' +
                              I18n.t('projects.index.hidden')
                            else
                              '<i class="fas fa-eye"></i>' +
                              I18n.t('projects.index.visible')
                            end
    json.set! 'users', project.user_count
    json.set! 'experiments', project.experiment_count
    json.set! 'tasks', project.task_count
    json.set! 'actions', render(
      partial: 'projects/index/project_actions_dropdown.html.erb',
      locals: { project: project, view: 'table' }
    )
  end
end
