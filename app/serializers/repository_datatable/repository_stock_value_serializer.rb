# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockValueSerializer < RepositoryBaseValueSerializer
    include Canaid::Helpers::PermissionsHelper

    def value
      data = {
        stock_formatted: value_object.formatted,
        stock_amount: value_object.data,
        low_stock_threshold: value_object.low_stock_threshold
      }
      if scope.dig(:options, :reminders_enabled) &&
         !scope[:repository].is_a?(RepositorySnapshot) &&
         value_object.data.present? &&
         value_object.low_stock_threshold.present?
        data[:reminder] = value_object.low_stock_threshold > value_object.data
        if data[:reminder] && (data[:stock_amount]).positive?
          data[:reminder_text] =
            I18n.t('repositories.item_card.reminders.stock_low', stock_formated: data[:stock_formatted])
        elsif data[:reminder]
          data[:reminder_text] = I18n.t('repositories.item_card.reminders.stock_empty')
        end
      end

      if data[:stock_amount] <= 0
        data[:reminder] = true
        data[:reminder_text] = I18n.t('repositories.item_card.reminders.stock_empty')
      end
      data
    end
  end
end
