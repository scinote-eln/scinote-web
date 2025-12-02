# frozen_string_literal: true

class StepTextSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :text, :urls, :text_view, :updated_at, :icon, :name, :placeholder, :parent_type

  def updated_at
    object.updated_at.to_i
  end

  def parent_type
    :step
  end

  def placeholder
    I18n.t('protocols.steps.text.placeholder')
  end

  def text_view
    user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.tinymce_render('text'),
                     simple_format: false,
                     tags: %w(img),
                     team: user.current_team)
  end

  def text
    sanitize_input(object.tinymce_render('text'))
  end

  def icon
    'sn-icon-result-text'
  end

  def urls
    return {} if object.destroyed? || !can_manage_step?(scope[:user] || @instance_options[:user], object.step)

    step = @instance_options[:step] || object.step_orderable_element.step
    {
      duplicate_url: duplicate_step_text_path(step, object),
      delete_url: step_text_path(step, object),
      update_url: step_text_path(step, object),
      move_url: move_step_text_path(step, object),
      move_targets_url: move_targets_step_text_path(step, object)
    }
  end
end
