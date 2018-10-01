# frozen_string_literal: true

json.data do
  json.array! @projects do |project|
    json.set! 'id', project.id
    json.set! 'archived', project.archived
    json.set! 'name', project.name
    json.set! 'created_at', I18n.l(project.created_at, format: :full)
    json.set! 'visibility', if project.visibility == 'hidden'
                              '<i class="fas fa-eye-slash"></i>' +
                              I18n.t('projects.index.hidden')
                            else
                              '<i class="fas fa-eye"></i>' +
                              I18n.t('projects.index.visible')
                            end
    json.set! 'user_count', project.user_count
    json.set! 'notification_count', project.notification_count
    json.set! 'comment_count', project.comment_count
  end
end
