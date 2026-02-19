# frozen_string_literal: true

module Api
  module V2
    class StepsController < ::Api::V1::StepsController
      def index
        steps = timestamps_filter(@protocol.steps).page(params.dig(:page, :number))
                                                  .per(params.dig(:page, :size))

        render jsonapi: steps, each_serializer: Api::V2::StepSerializer,
               include: include_params,
               rte_rendering: render_rte?,
               team: @team
      end

      def show
        render jsonapi: @step, serializer: Api::V2::StepSerializer,
               include: include_params,
               rte_rendering: render_rte?,
               team: @team
      end

      def create
        raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

        @protocol.transaction do
          @step = @protocol.steps.create!(
            step_params.merge!(completed: false,
                               user: current_user,
                               position: @protocol.number_of_steps,
                               last_modified_by_id: current_user.id)
          )
        end
        render jsonapi: @step, serializer: Api::V2::StepSerializer, status: :created
      end

      def update
        @step.assign_attributes(
          step_params.merge!(last_modified_by_id: current_user.id).merge!(parse_completed_attribute(step_params[:completed]))
        )

        return render body: nil, status: :no_content unless @step.changed?

        @step.save!
        if @step.saved_change_to_attribute?(:completed) || @step.saved_change_to_attribute?(:skipped_at)
          type_of = if step_params[:completed] == 'skipped'
                      :skip_step
                    else
                      @step.saved_change_to_attribute(:completed).last ? :complete_step : :uncomplete_step
                    end

          log_activity(type_of, my_module: @task.id,
                                num_completed: @protocol.steps.where(completed: true).count.to_s,
                                num_all: @protocol.steps.count.to_s,
                                num_skipped: @protocol.steps.where.not(skipped_at: nil).count.to_s)
        end

        render jsonapi: @step, serializer: Api::V2::StepSerializer, status: :ok
      end

      private

      def step_params
        raise TypeError unless params.require(:data).require(:type) == 'steps'

        params.require(:data).require(:attributes).permit(:name, :completed)
      end

      def permitted_includes
        %w(tables assets checklists checklists.checklist_items comments user form_responses)
      end

      def check_manage_permissions
        if step_params.key?(:completed) && step_params.except(:completed).blank?
          completed_bool = ActiveModel::Type::Boolean.new.cast(step_params[:completed])
          permission = if step_parms[:completed] == 'skipped'
                         can_skip_my_module_steps(@step.my_module)
                       elsif completed_bool
                         can_complete_my_module_steps?(@step.my_module)
                       elsif !completed_bool
                         can_uncomplete_my_module_steps?(@step.my_module)
                       else
                         false
                       end

          raise PermissionError.new(Step, :toggle_completion) unless permission
        else
          raise PermissionError.new(Step, :manage) unless can_manage_step?(@step)
        end
      end

      def parse_completed_attribute(completed)
        return if completed.nil?

        if completed == 'skipped'
          {
            completed: false,
            skipped_at: DateTime.now
          }
        else
          {
            completed: completed,
            skipped_at: nil
          }
        end
      end
    end
  end
end
