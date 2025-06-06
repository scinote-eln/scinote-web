# frozen_string_literal: true

class FavoriteSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include BreadcrumbsHelper

  attributes :id, :name, :code, :status, :breadcrumbs, :url

  def code
    object.item.code
  end

  def name
    object.item.name
  end

  def breadcrumbs
    subject = object.item
    generate_breadcrumbs(subject, []) if subject
  end

  def url
    case object.item_type
    when 'Project'
      experiments_path(project_id: object.item)
    when 'Experiment'
      my_modules_experiment_path(object.item)
    when 'MyModule'
      protocols_my_module_path(object.item)
    end
  end

  def status
    case object.item_type
    when 'MyModule'
      {
        name: object.item.my_module_status.name,
        color: object.item.my_module_status.color,
        light_color: object.item.my_module_status.light_color?
      }
    else
      case object.item.status
      when :not_started
        {
          name: I18n.t('projects.index.status.not_started'),
          color: Constants::STATUS_COLORS[:not_started],
          light_color: true
        }
      when :in_progress
        {
          name: I18n.t('projects.index.status.in_progress'),
          color: Constants::STATUS_COLORS[:in_progress],
          light_color: false
        }
      when :done
        {
          name: I18n.t('projects.index.status.done'),
          color: Constants::STATUS_COLORS[:done],
          light_color: false
        }
      end
    end
  end
end
