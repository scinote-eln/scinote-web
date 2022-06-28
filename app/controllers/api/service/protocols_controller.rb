# frozen_string_literal: true

module Api
  module Service
    class ProtocolsController < BaseController
      include Api::Service::ReorderValidation

      before_action :load_team, :load_project, :load_experiment, :load_task
      before_action :load_protocol, only: :reorder_steps
      before_action :validate_step_order, only: :reorder_steps

      def reorder_steps
        ActiveRecord::Base.transaction do
          step_reorder_params.each do |step_id, position|
            @protocol.steps.find(step_id).update!(position: position)
          end
        rescue StandardError
          head :bad_request
        end

        head :ok
      end

      private

      def step_reorder_params
        params.require(:step_order)
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
