# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateValueSerializer < RepositoryBaseValueSerializer
    def value
      Time.use_zone('UTC') do # all Date values are stored as UTC DateTime
        {
          formatted: I18n.l(object.data, format: :full_date),
          datetime: object.data.strftime('%Y/%m/%d %H:%M')
        }
      end
    end
  end
end