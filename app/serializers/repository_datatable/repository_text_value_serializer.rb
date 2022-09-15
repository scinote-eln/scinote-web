# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTextValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    include ActionView::Helpers::TextHelper
    include ApplicationHelper

    def value
      @user = scope[:user]
      {
        view: custom_auto_link(object.data, simple_format: true, team: scope[:team]),
        edit: object.data
      }
    end
  end
end
