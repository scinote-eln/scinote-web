# frozen_string_literal: true

class ChecklistItemSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :text, :checked, :position, :urls, :sa_text, :with_paragraphs

  def with_paragraphs
    object.text.include?("\n")
  end

  def sa_text
    user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.text,
                     simple_format: false,
                     tags: %w(img),
                     team: user.current_team)
  end

  def urls
    urls_list = {}
    return urls_list if object.destroyed? || !object.persisted?

    step = @instance_options[:step] || object.checklist.step_orderable_element.step

    if managable?
      urls_list[:update_url] = step_checklist_checklist_item_path(step, object.checklist, object)
      urls_list[:delete_url] = step_checklist_checklist_item_path(step, object.checklist, object)
    end

    if (!object.checked && checkable?) || (object.checked && uncheckable?)
      urls_list[:toggle_url] = toggle_step_checklist_checklist_item_path(step, object.checklist, object)
    end

    urls_list
  end

  def managable?
    return @instance_options[:managable_step] unless @instance_options[:managable_step].nil?

    step = @instance_options[:step] || object.checklist.step_orderable_element.step
    can_manage_step?(scope[:user] || @instance_options[:user], step)
  end

  def checkable?
    return @instance_options[:checkable_checklist] unless @instance_options[:checkable_checklist].nil?

    my_module = object.checklist.step_orderable_element.step.protocol.my_module
    can_check_my_module_steps?(scope[:user] || @instance_options[:user], my_module)
  end

  def uncheckable?
    return @instance_options[:uncheckable_checklist] unless @instance_options[:uncheckable_checklist].nil?

    my_module = object.checklist.step_orderable_element.step.protocol.my_module
    can_uncheck_my_module_steps?(scope[:user] || @instance_options[:user], my_module)
  end
end
