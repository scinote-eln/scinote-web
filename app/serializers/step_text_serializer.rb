# frozen_string_literal: true

class StepTextSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :text, :urls, :text_view, :updated_at, :icon, :name, :placeholder, :parent_type, :archived, :archived_by, :archived_on

  def updated_at
    object.updated_at.to_i
  end

  def parent_type
    :step
  end

  def archived
    object.archived?
  end

  def archived_by
    object.step_orderable_element.archived_by&.full_name
  end

  def archived_on
    I18n.l(object.step_orderable_element.archived_on, format: :full) if object.step_orderable_element.archived_on.present?
  end

  def placeholder
    I18n.t('protocols.steps.text.placeholder')
  end

  def text_view
    @user = scope[:user]
    custom_auto_link(object.tinymce_render('text'),
                     simple_format: false,
                     tags: %w(img),
                     team: object.step.protocol.team)
  end

  def text
    sanitize_input(object.tinymce_render('text'))
  end

  def icon
    'sn-icon-result-text'
  end

  def urls
    return {} if object.destroyed? || !can_manage_step?(scope[:user] || @instance_options[:user], object.step)

    step = object.step

    url_list = if object.archived?
                 {
                   restore_url: restore_step_text_path(step, object)
                 }
               else
                 {
                   duplicate_url: duplicate_step_text_path(step, object),
                   update_url: step_text_path(step, object),
                   move_url: move_step_text_path(step, object),
                   move_targets_url: move_targets_step_text_path(step, object)
                 }
               end
    if object.archived? || step.protocol.in_repository?
      url_list[:delete_url] = step_text_path(step, object)
    else
      url_list[:archive_url] = archive_step_text_path(step, object)
    end

    url_list
  end
end
