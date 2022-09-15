# frozen_string_literal: true

module Api
  module Service
    class ProtocolsController < BaseController
      include Api::Service::ReorderValidation

      before_action :load_protocol
      before_action :validate_step_order, only: :reorder_steps

      def reorder_steps
        @protocol.with_lock do
          step_reorder_params.each do |order|
            # rubocop:disable Rails/SkipsModelValidations
            @protocol.steps.find(order['id']).update_column(:position, order['position'])
            # rubocop:enable Rails/SkipsModelValidations
          end
          @protocol.touch
        rescue StandardError
          head :bad_request
        end

        render json: @protocol.steps, each_serializer: Api::V1::StepSerializer
      end

      private

      def load_protocol
        @protocol = Protocol.find(params.require(:protocol_id))
        raise PermissionError.new(Protocol, :manage) unless can_manage_protocol_in_module?(@protocol)
      end

      def step_reorder_params
        params.require(:step_order).map { |o| o.permit(:id, :position).to_h }
      end

      def validate_step_order
        unless reorder_params_valid?(@protocol.steps, step_reorder_params)
          render json: { error: I18n.t('activerecord.errors.models.protocol.attributes.step_order.invalid') },
                 status: :bad_request
        end
      end
    end
  end
end
