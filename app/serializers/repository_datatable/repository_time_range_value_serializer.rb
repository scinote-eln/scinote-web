# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTimeRangeValueSerializer < RepositoryBaseValueSerializer
    def value
      I18n.l(object.start_time, format: :time) + ' - ' + I18n.l(object.end_time, format: :time)
    end
  end
end
