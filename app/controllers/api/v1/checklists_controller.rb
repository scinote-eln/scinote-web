# frozen_string_literal: true

module Api
  module V1
    class ChecklistsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step
      before_action only: %i(show update destroy) do
        load_checklist(:id)
      end
      before_action :check_create_permissions, only: :create
      before_action :check_manage_permissions, only: :update
      before_action :check_delete_permissions, only: :destroy

      def index
        checklists = timestamps_filter(@step.checklists)
        checklists = archived_filter(checklists, default_to_active: true)
        checklists = checklists.page(params.dig(:page, :number)).per(params.dig(:page, :size))

        render jsonapi: checklists, each_serializer: ChecklistSerializer, include: include_params
      end

      def show
        render jsonapi: @checklist, serializer: ChecklistSerializer, include: include_params
      end

      def create
        checklist = @step.checklists.new(checklist_params.merge!(created_by: current_user))
        @step.with_lock do
          checklist.save!
          @step.step_orderable_elements.create!(
            position: @step.next_element_position,
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

      def check_create_permissions
        raise PermissionError.new(Checklist, :create) unless can_manage_step?(@step)
      end

      def check_manage_permissions
        raise PermissionError.new(Checklist, :manage) unless can_manage_step_checklist?(@checklist)
      end

      def check_delete_permissions
        raise PermissionError.new(Checklist, :delete) unless can_delete_step_checklist?(@checklist)
      end
    end
  end
end
