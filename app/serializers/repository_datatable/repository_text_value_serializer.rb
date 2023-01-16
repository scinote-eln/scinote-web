# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTextValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    include ActionView::Helpers::TextHelper
    include ApplicationHelper

    def value
      @user = scope[:user]
      {
        view: custom_auto_link(value_object.data, simple_format: true, team: scope[:team]),
        edit: value_object.data
      }
    end
  end
end
