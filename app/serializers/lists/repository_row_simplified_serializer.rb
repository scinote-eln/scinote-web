# frozen_string_literal: true

module Lists
  class RepositoryRowSimplifiedSerializer < ActiveModel::Serializer
    include ActionView::Helpers::NumberHelper
    include RepositoryDatatableHelper

    attribute :code
    attribute :name, if: -> { instance_options[:can_read_repository] }
    attribute :has_active_reminders, if: -> { instance_options[:can_read_repository] && instance_options[:with_reminders] }
    attribute :stock, if: -> { instance_options[:can_read_repository] && instance_options[:with_stock_management] }

    def has_active_reminders
      object.has_active_reminders
    end

    def stock
      repository = object.repository
      stock_cell = object.repository_stock_cell

      stock_object =
        if stock_cell.present?
          serialize_repository_cell_value(stock_cell, repository.team, repository)
        else
          {}
        end
      stock_object[:display_warnings] = display_stock_warnings?(repository)
      stock_object[:stock_status] = object.repository_stock_cell&.value&.status

      stock_object[:stock_managable] = false
      if repository.is_a?(RepositorySnapshot)
        stock_object[:consumed_stock] =
          if object.repository_stock_consumption_value.present?
            serialize_repository_cell_value(object.repository_stock_consumption_cell, repository.team, repository)
          else
            {}
          end
      else
        stock_object[:consumed_stock] = {}
        if object.active?
          stock_object[:consumed_stock][:update_stock_consumption_url] =
            Rails.application.routes.url_helpers.consume_modal_my_module_repository_path(
              instance_options[:my_module], repository, row_id: object.id
            )
        end
        consumed_stock_formatted = number_with_precision(object.consumed_stock,
                                                         precision: repository.repository_stock_column.metadata['decimals'].to_i,
                                                         strip_insignificant_zeros: true)
        stock_object[:consumed_stock][:value] = {
          consumed_stock: object.consumed_stock,
          consumed_stock_formatted: "#{consumed_stock_formatted || 0} #{object.repository_stock_value&.repository_stock_unit_item&.data}"
        }
      end

      stock_object[:consumed_stock][:stock_present] = stock_cell.present?
      stock_object[:consumed_stock][:consumption_permitted] = object.active? && instance_options[:can_consume_stock]
      stock_object
    end
  end
end
