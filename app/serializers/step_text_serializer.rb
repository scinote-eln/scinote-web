# frozen_string_literal: true

class StepTextSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :text, :urls, :text_view, :updated_at

  def updated_at
    object.updated_at.to_i
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

  def urls
    return if object.destroyed?

    {
      delete_url: step_text_path(object.step, object),
      update_url: step_text_path(object.step, object)
    }
  end
end
