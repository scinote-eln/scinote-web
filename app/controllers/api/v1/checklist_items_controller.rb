# frozen_string_literal: true

module Api
  module V1
    class ChecklistItemsController < BaseController
      include ApplicationHelper

      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step, :load_checklist
      before_action only: :show do
        load_checklist_item(:id)
      end
      before_action :load_checklist_item_for_managing, only: %i(update destroy)

      def index
        checklist_items =
          timestamps_filter(@checklist.checklist_items).page(params.dig(:page, :number))
                                                       .per(params.dig(:page, :size))

        render jsonapi: checklist_items, each_serializer: ChecklistItemSerializer
      end

      def show
        render jsonapi: @checklist_item, serializer: ChecklistItemSerializer
      end

      def create
        raise PermissionError.new(Protocol, :create) unless can_manage_protocol_in_module?(@protocol)

        checklist_item = @checklist.checklist_items.create!(checklist_item_params.merge!(created_by: current_user))

        render jsonapi: checklist_item, serializer: ChecklistItemSerializer, status: :created
      end

      def update
        @checklist_item.assign_attributes(checklist_item_params)

        if @checklist_item.changed? && @checklist_item.save!
          if @checklist_item.saved_change_to_attribute?(:checked)
            completed_items = @checklist_item.checklist.checklist_items.where(checked: true).count
            all_items = @checklist_item.checklist.checklist_items.count
            text_activity = smart_annotation_parser(@checklist_item.text).gsub(/\s+/, ' ')
            type_of = if @checklist_item.saved_change_to_attribute(:checked).last
                        :check_step_checklist_item
                      else
                        :uncheck_step_checklist_item
                      end
            log_activity(type_of,
                         my_module: @task.id,
                         step: @step.id,
                         step_position: { id: @step.id, value_for: 'position_plus_one' },
                         checkbox: text_activity,
                         num_completed: completed_items.to_s,
                         num_all: all_items.to_s)
          end
          render jsonapi: @checklist_item, serializer: ChecklistItemSerializer, status: :ok
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @checklist_item.destroy!
        render body: nil
      end

      private

      def checklist_item_params
        raise TypeError unless params.require(:data).require(:type) == 'checklist_items'

        params.require(:data).require(:attributes).permit(:text, :checked, :position)
      end

      def load_checklist_item_for_managing
        @checklist_item = @checklist.checklist_items.find(params.require(:id))
        raise PermissionError.new(Protocol, :manage) unless can_manage_protocol_in_module?(@protocol)
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
