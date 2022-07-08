# frozen_string_literal: true

class ChecklistItemSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :text, :checked, :position, :urls, :sa_text

  def sa_text
    @user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.text,
                     simple_format: false,
                     tags: %w(img),
                     team: object.checklist.step.protocol.team)
  end

  def urls
    return {} if object.destroyed? ||
                 !object.persisted? ||
                 !can_manage_step?(scope[:user] || @instance_options[:user], object.checklist.step)

    {
      update_url: step_checklist_checklist_item_path(object.checklist.step, object.checklist, object),
      delete_url: step_checklist_checklist_item_path(object.checklist.step, object.checklist, object)
    }
  end
end
