# frozen_string_literal: true

module Lists
  class RepositoryRowSerializer < ActiveModel::Serializer
    include ActionView::Helpers::NumberHelper
    include RepositoryDatatableHelper

    attributes :code, :name, :created_at, :created_by, :updated_at, :last_modified_by, :archived, :archived_on, :archived_by,
               :assigned_tasks_count, :connections_count
    attribute :has_active_reminders, if: -> { instance_options[:with_reminders] }
    attribute :assigned, if: -> { instance_options[:my_module] && !instance_options[:assigned_view] }
    attribute :stock, if: -> { instance_options[:with_stock_management] }

    def attributes(requested_attrs = nil, reload = false)
      data = super(requested_attrs, reload)
      repository = object.repository
      reminders_enabled = instance_options[:reminders_enabled]
      custom_cells = object.repository_cells
      custom_cells = custom_cells.filter { |cell| cell.value_type != 'RepositoryStockValue' } if instance_options[:with_stock_management]

      custom_cells.each do |cell|
        data["col_#{cell.repository_column.id}"] = serialize_repository_cell_value(cell, repository.team, repository, reminders_enabled: reminders_enabled)
      end

      data
    end

    def created_at
      I18n.l(object.created_at, format: :full)
    end

    def created_by
      object[:created_by_full_name]
    end

    def updated_at
      I18n.l(object.updated_at, format: :full)
    end

    def last_modified_by
      object[:last_modified_by_full_name]
    end

    def archived
      object.attributes[:archived]
    end

    def archived_on
      I18n.l(object.attributes[:archived_on], format: :full) if object.attributes[:archived_on]
    end

    def archived_by
      object[:archived_by_full_name]
    end

    def assigned_tasks_count
      object.assigned_my_modules_count
    end

    def connections_count
      "#{object.parent_connections_count || 0} / #{object.child_connections_count || 0}"
    end

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
          { stock_url: Rails.application.routes.url_helpers.new_repository_stock_repository_repository_row_url(repository, object) }
        end
      stock_object[:display_warnings] = display_stock_warnings?(repository)
      stock_object[:stock_status] = object.repository_stock_cell&.value&.status
      stock_object[:stock_managable] = instance_options[:can_manage_stock]

      if instance_options[:can_consume_stock]
        consumed_stock_formatted = number_with_precision(object.consumed_stock,
                                                         precision: repository.repository_stock_column.metadata['decimals'].to_i,
                                                         strip_insignificant_zeros: true)
        stock_object[:consumed_stock] = {
          stock_present: stock_cell.present?,
          consumption_permitted: object.active? && instance_options[:can_consume_stock],
          updateStockConsumptionUrl:
            Rails.application.routes.url_helpers.consume_modal_my_module_repository_path(instance_options[:my_module], repository, row_id: object.id),
          value: {
            consumed_stock: object.consumed_stock,
            consumed_stock_formatted: "#{consumed_stock_formatted || 0} #{object.repository_stock_value&.repository_stock_unit_item&.data}"
          }
        }
      end
      stock_object
    end
  end
end
