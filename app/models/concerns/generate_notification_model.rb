# frozen_string_literal: true

module GenerateNotificationModel
  extend ActiveSupport::Concern
  include GlobalActivitiesHelper

  included do
    after_create :generate_notification
  end

  def generate_notification_from_activity
    return if notification_recipients.none?

    message = generate_activity_content(self, no_links: true, no_custom_links: true)
    description = generate_notification_description_elements(subject).reverse.join(' | ')

    notification = Notification.create(
      type_of: notification_type,
      title: sanitize_input(message),
      message: sanitize_input(description),
      generator_user_id: owner.id
    )

    notification_recipients.each do |user|
      notification.create_user_notification(user)
    end
  end

  protected

  def notification_recipients
    users = []

    case subject
    when Project
      users = subject.users
    when Experiment
      users = subject.users
    when MyModule
      users = subject.designated_users
      # Also send to the user that was unassigned,
      # and is therefore no longer present on the module.
      if type_of == 'undesignate_user_from_my_module'
        users += User.where(id: values.dig('message_items', 'user_target', 'id'))
      end
    when Protocol
      users = subject.in_repository? ? [] : subject.my_module.designated_users
    when Result
      users = subject.my_module.designated_users
    when Repository
      users = subject.team.users
    when Team
      users = subject.users
    when Report
      users = subject.team.users
    when ProjectFolder
      users = subject.team.users
    end
    users - [owner]
  end

  # This method returns unsanitized elements. They must be sanitized before saving to DB
  def generate_notification_description_elements(object, elements = [])
    case object
    when Project
      path = Rails.application.routes.url_helpers.project_path(object)
      elements << "#{I18n.t('search.index.project')} <a href='#{path}'>#{object.name}</a>"
    when Experiment
      path = Rails.application.routes.url_helpers.my_modules_experiment_path(object)
      elements << "#{I18n.t('search.index.experiment')} <a href='#{path}'>#{object.name}</a>"
      generate_notification_description_elements(object.project, elements)
    when MyModule
      path = if object.archived?
               Rails.application.routes.url_helpers.my_modules_experiment_path(object.experiment, view_mode: :archived)
             else
               Rails.application.routes.url_helpers.protocols_my_module_path(object)
             end
      elements << "#{I18n.t('search.index.module')} <a href='#{path}'>#{object.name}</a>"
      generate_notification_description_elements(object.experiment, elements)
    when Protocol
      if object.in_repository?
        path = Rails.application.routes.url_helpers.protocols_path(team: object.team.id)
        elements << "#{I18n.t('search.index.protocol')} <a href='#{path}'>#{object.name}</a>"
        generate_notification_description_elements(object.team, elements)
      else
        generate_notification_description_elements(object.my_module, elements)
      end
    when Result
      generate_notification_description_elements(object.my_module, elements)
    when Repository
      path = Rails.application.routes.url_helpers.repository_path(object, team: object.team.id)
      elements << "#{I18n.t('search.index.repository')} <a href='#{path}'>#{object.name}</a>"
      generate_notification_description_elements(object.team, elements)
    when Team
      path = Rails.application.routes.url_helpers.projects_path(team: object.id)
      elements << "#{I18n.t('search.index.team')} <a href='#{path}'>#{object.name}</a>"
    when Report
      path = Rails.application.routes.url_helpers.reports_path(team: object.team.id)
      elements << "#{I18n.t('search.index.report')} <a href='#{path}'>#{object.name}</a>"
      generate_notification_description_elements(object.team, elements)
    when ProjectFolder
      generate_notification_description_elements(object.team, elements)
    end

    elements
  end

  def notifiable?
    type_of.in? ::Extends::NOTIFIABLE_ACTIVITIES
  end

  private

  def generate_notification
    CreateNotificationFromActivityJob.perform_later(self) if notifiable?
  end

  def notification_type
    return :recent_changes unless instance_of?(Activity)

    if type_of.in? Activity::ASSIGNMENT_TYPES
      :assignment
    else
      :recent_changes
    end
  end
end
