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
            auto_link(
              sanitize_input(value_object.data),
              html: { target: '_blank' },
              link: :urls
            ),
        edit: value_object.data
      }
    end
  end
end
