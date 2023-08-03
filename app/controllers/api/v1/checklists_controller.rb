# frozen_string_literal: true

module Api
  module V1
    class ChecklistsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action only: :show do
        load_checklist(:id)
      end
      before_action :load_checklist_for_managing, only: %i(update destroy)

      def index
        checklists =
          timestamps_filter(@step.checklists).page(params.dig(:page, :number))
                                             .per(params.dig(:page, :size))

        render jsonapi: checklists, each_serializer: ChecklistSerializer, include: include_params
      end

      def show
        render jsonapi: @checklist, serializer: ChecklistSerializer, include: include_params
      end

      def create
        raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

        checklist = @step.checklists.new(checklist_params.merge!(created_by: current_user))
        @step.with_lock do
          checklist.save!
          @step.step_orderable_elements.create!(
            position: @step.step_orderable_elements.size,
            orderable: checklist
          )
        end

        render jsonapi: checklist, serializer: ChecklistSerializer, status: :created
      end

      def update
        @checklist.assign_attributes(checklist_params)

        if @checklist.changed? && @checklist.save!
          render jsonapi: @checklist, serializer: ChecklistSerializer, status: :ok
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @checklist.destroy!
        render body: nil
      end

      private

      def checklist_params
        raise TypeError unless params.require(:data).require(:type) == 'checklists'

        params.require(:data).require(:attributes).permit(:name)
      end

      def permitted_includes
        %w(checklist_items)
      end

      def load_checklist_for_managing
        @checklist = @step.checklists.find(params.require(:id))
        raise PermissionError.new(Protocol, :manage) unless can_manage_protocol_in_module?(@protocol)
      end
    end
  end
end
