# frozen_string_literal: true

module StepElements
  class ChecklistItemsController < ApplicationController
    include ApplicationHelper

    before_action :load_vars
    before_action :load_checklist, only: %i(update destroy)
    before_action :check_manage_permissions, only: %i(create update destroy)

    def create
      checklist_item = @checklist.checklist_items.build(checklist_item_params.merge!(created_by: current_user))
      checklist_item.save!
      render json: checklist_item, serializer: ChecklistItemSerializer
    rescue ActiveRecord::RecordInvalid
      render json: checklist_item, serializer: ChecklistItemSerializer, status: :unprocessable_entity
    end

    def update
      @checklist_item.assign_attributes(checklist_item_params)

      if @checklist_item.save! && @checklist_item.saved_change_to_attribute?(:checked)
        completed_items = @checklist_item.checklist.checklist_items.where(checked: true).count
        all_items = @checklist_item.checklist.checklist_items.count
        text_activity = smart_annotation_parser(@checklist_item.text).gsub(/\s+/, ' ')
        type_of = if @checklist_item.saved_change_to_attribute(:checked).last
                    :check_step_checklist_item
                  else
                    :uncheck_step_checklist_item
                  end
        log_activity(type_of,
                     my_module: @step.protocol.my_module.id,
                     step: @step.id,
                     step_position: { id: @step.id, value_for: 'position_plus_one' },
                     checkbox: text_activity,
                     num_completed: completed_items.to_s,
                     num_all: all_items.to_s)
      end

      render json: @checklist_item, serializer: ChecklistItemSerializer
    rescue ActiveRecord::RecordInvalid
      render json: @checklist_item, serializer: ChecklistItemSerializer, status: :unprocessable_entity
    end

    def destroy
      if @checklist_item.destroy
        render json: @checklist_item, serializer: ChecklistItemSerializer
      else
        render json: @checklist_item, serializer: ChecklistItemSerializer, status: :unprocessable_entity
      end
    end

    def reorder
      ActiveRecord::Base.transaction do
        params[:checklist_item_positions].each do |id, position|
          @checklist.checklist_items.find(id).update_column(:position, position)
        end
      end

      render json: params[:checklist_item_positions], status: :ok
    end

    private

    def check_manage_permissions
      render_403 unless can_manage_step?(@step)
    end

    def checklist_item_params
      params.require(:attributes).permit(:checked, :text, :position)
    end

    def load_vars
      @step = Step.find_by(id: params[:step_id])
      return render_404 unless @step

      @checklist = @step.checklists.find_by(id: params[:checklist_id])
      return render_404 unless @checklist
    end

    def load_checklist
      @checklist_item = @checklist.checklist_items.find_by(id: params[:id])
      return render_404 unless @checklist_item
    end

    def log_activity(type_of, message_items = {})
      default_items = { step: @step.id, step_position: { id: @step.id, value_for: 'position_plus_one' } }
      message_items = default_items.merge(message_items)

      Activities::CreateActivityService.call(activity_type: type_of,
                                             owner: current_user,
                                             subject: @step.protocol,
                                             team: @step.protocol.team,
                                             project: @step.protocol.my_module.experiment.project,
                                             message_items: message_items)
    end
  end
end
