# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTextValueSerializer < RepositoryBaseValueSerializer
    include InputSanitizeHelper
    include ActionView::Helpers::TextHelper
    include ApplicationHelper

    def value
      @user = scope[:user]
      {
        view:
          if value_object.has_smart_annotation?
            custom_auto_link(value_object.data, simple_format: true, team: scope[:team])
          else
            auto_link(
              sanitize_input(value_object.data),
              html: { target: '_blank' },
              link: :urls
            )
          end,
        edit: value_object.data
      }
    end
  end
end
