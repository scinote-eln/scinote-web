# frozen_string_literal: true

module StepElements
  class ChecklistItemsController < ApplicationController
    include ApplicationHelper
    include StepsActions

    before_action :load_vars
    before_action :load_checklist_item, only: %i(update toggle destroy)
    before_action :check_toggle_permissions, only: %i(toggle)
    before_action :check_manage_permissions, only: %i(create update destroy)

    def index
      render json: @checklist.checklist_items, each_serializer: ChecklistItemSerializer, user: current_user
    end

    def create
      checklist_item = @checklist.checklist_items.new(checklist_item_params.merge!(created_by: current_user))
      new_items = []
      ActiveRecord::Base.transaction do
        new_items = checklist_item.save_multiline!(after_id: params[:after_id])
        new_items.each do |item|
          log_activity(
            "#{@step.protocol.in_module? ? :task : :protocol}_step_checklist_item_added",
            {
              checklist_item: item.text,
              checklist_name: @checklist.name
            }
          )
          checklist_item_annotation(@step, item)
        end
      end

      render json: new_items, each_serializer: ChecklistItemSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      render json: { errors: checklist_item.errors }, status: :unprocessable_entity
    end

    def update
      old_text = @checklist_item.text
      @checklist_item.assign_attributes(
        checklist_item_params.except(:position, :id).merge(last_modified_by: current_user)
      )
      new_items = []
      ActiveRecord::Base.transaction do
        new_items = @checklist_item.save_multiline!
        new_items.each_with_index do |item, i|
          log_activity(
            "#{@step.protocol.in_module? ? :task : :protocol}_step_checklist_item_#{i.zero? ? 'edited' : 'added'}",
            checklist_item: item.text,
            checklist_name: @checklist.name
          )
          checklist_item_annotation(@step, item, old_text)
        end
      end

      render json: new_items, each_serializer: ChecklistItemSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      render json: { errors: @checklist_item.errors }, status: :unprocessable_entity
    end

    def toggle
      @checklist_item.assign_attributes(
        checklist_toggle_item_params.merge(last_modified_by: current_user)
      )

      if @checklist_item.save!
        completed_items = @checklist_item.checklist.checklist_items.where(checked: true).count
        all_items = @checklist_item.checklist.checklist_items.count
        text_activity = smart_annotation_parser(@checklist_item.text).gsub(/\s+/, ' ')
        type_of = if @checklist_item.saved_change_to_attribute(:checked).last
                    :check_step_checklist_item
                  else
                    :uncheck_step_checklist_item
                  end
        log_activity(type_of,
                     checkbox: text_activity,
                     num_completed: completed_items.to_s,
                     num_all: all_items.to_s)
      end

      render json: @checklist_item, serializer: ChecklistItemSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      render json: @checklist_item, serializer: ChecklistItemSerializer,
                                    user: current_user,
                                    status: :unprocessable_entity
    end

    def destroy
      if @checklist_item.destroy
        log_activity(
          "#{@step.protocol.in_module? ? :task : :protocol}_step_checklist_item_deleted",
          checklist_item: @checklist_item.text,
          checklist_name: @checklist.name
        )
        render json: @checklist_item, serializer: ChecklistItemSerializer, user: current_user
      else
        render json: @checklist_item, serializer: ChecklistItemSerializer,
                                      user: current_user,
                                      status: :unprocessable_entity
      end
    end

    def reorder
      checklist_item = @checklist.checklist_items.find(params[:id])
      ActiveRecord::Base.transaction do
        insert_at = (@checklist.checklist_items.find_by(id: params[:after_id])&.position || 0)
        checklist_item.insert_at(insert_at)
      end
      render json: params[:checklist_item_positions], status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: { errors: checklist_item.errors }, status: :conflict
    end

    private

    def check_toggle_permissions
      if ActiveModel::Type::Boolean.new.cast(checklist_toggle_item_params[:checked])
        render_403 unless can_check_my_module_steps?(@step.protocol.my_module)
      else
        render_403 unless can_uncheck_my_module_steps?(@step.protocol.my_module)
      end
    end

    def check_manage_permissions
      render_403 unless can_manage_step?(@step)
    end

    def checklist_item_params
      params.require(:attributes).permit(:text, :position, :id, :with_paragraphs)
    end

    def checklist_toggle_item_params
      params.require(:attributes).permit(:checked)
    end

    def load_vars
      @step = Step.find_by(id: params[:step_id])
      return render_404 unless @step

      @protocol = @step.protocol

      @checklist = @step.checklists.find_by(id: params[:checklist_id])
      return render_404 unless @checklist
    end

    def load_checklist_item
      @checklist_item = @checklist.checklist_items.find_by(id: params[:id])
      return render_404 unless @checklist_item
    end

    def log_activity(type_of, message_items = {})
      Activities::CreateActivityService.call(
        activity_type: type_of,
        owner: current_user,
        subject: @step.protocol,
        team: @step.protocol.team,
        project: @step.protocol.in_module? ? @step.protocol.my_module.project : nil,
        message_items: message_items.merge(step_message_items)
      )
    end

    def step_message_items
      items = {
        step: @step.id,
        step_position: { id: @step.id, value_for: 'position_plus_one' }
      }

      items[:my_module] = @step.protocol.my_module.id if @step.protocol.in_module?

      items
    end
  end
end
