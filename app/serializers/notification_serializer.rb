# frozen_string_literal: true

class NotificationSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :title, :message, :created_at, :read_at, :type, :breadcrumbs, :checked, :today

  def title
    object.to_notification.title
  end

  def breadcrumbs
    subject = object.to_notification.subject
    generate_breadcrumbs(subject, []) if subject
  end

  def message
    object.to_notification.message
  end

  def created_at
    I18n.l(object.created_at, format: :full)
  end

  def today
    object.created_at.today?
  end

  def checked
    object.read_at.present?
  end

  private

  def generate_breadcrumbs(subject, breadcrumbs)
    case subject
    when Project
      parent = subject.team
      url = project_path(subject)
    when Experiment
      parent = subject.project
      url = my_modules_experiment_path(subject)
    when MyModule
      parent = subject.experiment
      url = protocols_my_module_path(subject)
    when Protocol
      if subject.in_repository?
        parent = subject.team
        url = protocol_path(subject)
      else
        parent = subject.my_module
        url = protocols_my_module_path(subject.my_module)
      end
    when Result
      parent = subject.my_module
      url = my_module_results_path(subject.my_module)
    when ProjectFolder
      parent = subject.team
      url = project_folder_path(subject)
    when RepositoryBase
      parent = subject.team
      url = repository_path(subject)
    when RepositoryRow
      parent = subject.team
      url = repository_path(subject.repository)
    when LabelTemplate
      parent = subject.team
      url = label_template_path(subject)
    when Team
      parent = nil
      url = projects_path
    end

    breadcrumbs << { name: subject.name, url: url } if subject.name.present?

    if parent
      generate_breadcrumbs(parent, breadcrumbs)
    else
      breadcrumbs.reverse
    end
  end
end
