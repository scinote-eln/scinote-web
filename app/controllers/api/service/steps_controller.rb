# frozen_string_literal: true

module Api
  module Service
    class StepsController < BaseController
      include Api::Service::ReorderValidation
      before_action :load_step
      before_action :validate_element_order, only: :reorder_elements

      def reorder_elements
        @step.with_lock do
          step_element_reorder_params.each do |order|
            # rubocop:disable Rails/SkipsModelValidations
            @step.step_orderable_elements.find(order['id']).update_column(:position, order['position'])
            # rubocop:enable Rails/SkipsModelValidations
          end
          @step.touch
        rescue StandardError
          head :bad_request
        end

        render json: @step.step_orderable_elements, each_serializer: Api::V1::StepOrderableElementSerializer
      end

      private

      def load_step
        @step = Step.find(params.require(:step_id))
        raise PermissionError.new(Protocol, :manage) unless can_manage_protocol_in_module?(@step.protocol)
      end

      def step_element_reorder_params
        params.require(:step_element_order).map { |o| o.permit(:id, :position).to_h }
      end

      def validate_element_order
        unless reorder_params_valid?(@step.step_orderable_elements, step_element_reorder_params)
          render(
            json:
              {
                error: I18n.t('activerecord.errors.models.step.attributes.step_orderable_elements_order.invalid')
              },
            status: :bad_request
          )
        end
      end
    end
  end
end
