# frozen_string_literal: true

module Api
  module V1
    class StepsController < BaseController
      include Api::V1::ExtraParams

      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol
      before_action only: %i(show update destroy) do
        load_step(:id)
      end
      before_action :check_manage_permissions, only: :update
      before_action :check_delete_permissions, only: :destroy

      def index
        steps = timestamps_filter(@protocol.steps).page(params.dig(:page, :number))
                                                  .per(params.dig(:page, :size))

        render jsonapi: steps, each_serializer: StepSerializer,
                               include: include_params,
                               rte_rendering: render_rte?,
                               team: @team
      end

      def show
        render jsonapi: @step, serializer: StepSerializer,
                               include: include_params,
                               rte_rendering: render_rte?,
                               team: @team
      end

      def create
        raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

        @protocol.transaction do
          @step = @protocol.steps.create!(
            step_params.except(:description)
                       .merge!(completed: false,
                               user: current_user,
                               position: @protocol.number_of_steps,
                               last_modified_by_id: current_user.id)
          )
          if step_params[:description]
            step_text = @step.step_texts.build(text: step_params[:description])
            @step.step_orderable_elements.create!(
              position: 0,
              orderable: step_text
            )
          end
        end

        render jsonapi: @step, serializer: StepSerializer, status: :created
      end

      def update
        @step.assign_attributes(
          step_params.except(:description).merge!(last_modified_by_id: current_user.id)
        )

        if step_params[:description]
          (@step.description_step_text || @step.step_texts.create!).update!(
            text: step_params[:description]
          )
        end

        if @step.changed? && @step.save!
          if @step.saved_change_to_attribute?(:completed)
            completed_steps = @protocol.steps.where(completed: true).count
            all_steps = @protocol.steps.count
            type_of = @step.saved_change_to_attribute(:completed).last ? :complete_step : :uncomplete_step
            log_activity(type_of, my_module: @task.id,
                                  num_completed: completed_steps.to_s,
                                  num_all: all_steps.to_s)
          end
          render jsonapi: @step, serializer: StepSerializer, status: :ok
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @step.destroy!
        render body: nil
      end

      private

      def step_params
        raise TypeError unless params.require(:data).require(:type) == 'steps'

        params.require(:data).require(:attributes).permit(:name, :description, :completed)
      end

      def permitted_includes
        %w(tables assets checklists checklists.checklist_items comments user)
      end

      def check_manage_permissions
        if step_params.key?(:completed) && step_params.except(:completed).blank?
          raise PermissionError.new(Step, :toggle_completion) unless can_complete_or_checkbox_step?(@step.protocol)
        else
          raise PermissionError.new(Step, :manage) unless can_manage_step?(@step)
        end
      end

      def check_delete_permissions
        raise PermissionError.new(Step, :delete) unless can_manage_step?(@step)
      end

      def log_activity(type_of, message_items = {})
        default_items = { step: @step.id, step_position: { id: @step.id, value_for: 'position_plus_one' } }
        message_items = default_items.merge(message_items)

        Activities::CreateActivityService.call(activity_type: type_of,
                                               owner: current_user,
                                               subject: @protocol,
                                               team: @team,
                                               project: @project,
                                               message_items: message_items)
      end
    end
  end
end
