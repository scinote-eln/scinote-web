# frozen_string_literal: true

module Api
  module Service
    class ProtocolsController < BaseController
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
        # contains all step ids, positions have values from 0 to number of steps - 1
        valid_step_order =
          @protocol.steps.order(:id).pluck(:id) == step_reorder_params.pluck(:id).sort &&
          step_reorder_params.pluck(:position).sort == (0...step_reorder_params.length).to_a

        unless valid_step_order
          render json: { error: I18n.t('activerecord.errors.models.protocol.attributes.step_order.invalid') },
                 status: :bad_request
        end
      end
    end
  end
end
