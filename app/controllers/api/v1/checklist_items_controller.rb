# frozen_string_literal: true

module Api
  module V1
    class ChecklistItemsController < BaseController
      before_action :load_team, :load_project, :load_experiment, :load_task, :load_protocol, :load_step, :load_checklist
      before_action only: :show do
        load_checklist_item(:id)
      end
      before_action :load_checklist_item_for_managing, only: %i(update destroy)

      def index
        checklist_items = @checklist.checklist_items.page(params.dig(:page, :number)).per(params.dig(:page, :size))

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
    end
  end
end
