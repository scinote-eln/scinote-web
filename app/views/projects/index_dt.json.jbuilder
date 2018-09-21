# frozen_string_literal: true

json.recordsTotal @projects.total_count
json.recordsFiltered @projects.length
json.data do
  json.array! @projects do |project|
    json.set! 'DT_RowId', project.id
    json.set! '1', if project.archived
                     '<i class="fas fa-archive"></i>' +
                     I18n.t('projects.index.archived')
                   else
                     '<i class="fas fa-arrow-alt-circle-right"></i>' +
                     I18n.t('projects.index.active')
                   end
    json.set! '2', project.name
    json.set! '3', I18n.l(project.created_at, format: :full)
    json.set! '4', if project.visibility == 'hidden'
                     '<i class="fas fa-eye-slash"></i>' +
                     I18n.t('projects.index.hidden')
                   else
                     '<i class="fas fa-eye"></i>' +
                     I18n.t('projects.index.visible')
                   end
    json.set! '5', project.user_count
    json.set! '6', project.experiment_count
    json.set! '7', project.task_count
  end
end
