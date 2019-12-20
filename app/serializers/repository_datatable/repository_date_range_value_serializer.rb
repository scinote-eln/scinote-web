# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateRangeValueSerializer < RepositoryBaseValueSerializer
    def value
      I18n.l(object.start_time, format: :full_date) + ' - ' + I18n.l(object.end_time, format: :full_date)
    end
  end
end
