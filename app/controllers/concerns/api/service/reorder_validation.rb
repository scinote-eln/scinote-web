# frozen_string_literal: true

module Api
  module Service
    module ReorderValidation
      extend ActiveSupport::Concern

      def reorder_params_valid?(collection, reorder_params)
        # contains all collection ids, positions have values from 0 to number of items in collection - 1

        collection.order(:id).pluck(:id) == reorder_params.pluck(:id).sort &&
          reorder_params.pluck(:position).sort == (0...reorder_params.length).to_a
      end
    end
  end
end
