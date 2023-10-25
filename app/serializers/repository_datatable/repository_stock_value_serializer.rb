# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockValueSerializer < RepositoryBaseValueSerializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def value
      data = {
        stock_formatted: value_object.formatted,
        stock_amount: value_object.data,
        low_stock_threshold: value_object.low_stock_threshold,
        stock_url:
      }
      data.merge(reminder_values)
    end

    private

    def reminder_values
      data = {}
      if scope.dig(:options, :reminders_enabled) &&
        !scope[:repository].is_a?(RepositorySnapshot) &&
        value_object.data.present? &&
        value_object.low_stock_threshold.present?
       data[:reminder] = value_object.low_stock_threshold > value_object.data
       if data[:reminder] && value_object.data&.positive?
         data[:reminder_text] =
           I18n.t('repositories.item_card.reminders.stock_low', stock_formated: value_object.formatted)
       elsif data[:reminder]
         data[:reminder_text] = I18n.t('repositories.item_card.reminders.stock_empty')
       end
     end

     if value_object.data && value_object.data <= 0
       data[:reminder] = true
       data[:reminder_text] = I18n.t('repositories.item_card.reminders.stock_empty')
     end
     data
    end

    def stock_url
      if scope[:repository] && scope.dig(:options, :repository_row)
        edit_repository_stock_repository_repository_row_url(
          scope[:repository], scope[:options][:repository_row])
      end
    end
  end
end
