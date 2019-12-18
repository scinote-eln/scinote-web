# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateTimeRangeValueSerializer < RepositoryBaseValueSerializer
    def value
      I18n.l(object.start_time, format: :full_with_comma) + ' - ' + I18n.l(object.end_time, format: :full_with_comma)
    end
  end
end
