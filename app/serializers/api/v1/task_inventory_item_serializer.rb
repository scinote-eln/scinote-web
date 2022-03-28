# frozen_string_literal: true

module Api
  module V1
    class TaskInventoryItemSerializer < InventoryItemSerializer
      attribute :stock_consumption, if: -> { object.repository_stock_cell.present? }

      def stock_consumption
        object.my_module_repository_rows
              .find_by(my_module: instance_options[:my_module])
              .stock_consumption
      end
    end
  end
end
