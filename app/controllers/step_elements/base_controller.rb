# frozen_string_literal: true

module StepElements
  class BaseController < ApplicationController
    before_action :load_step_and_protocol

    def move_targets
      render json: { targets: @protocol.steps.active.unlocked.order(:position).where.not(id: @step.id).map { |i| [i.id, i.name] } }
    end

    def lock
      ActiveRecord::Base.transaction do
        @element.update!(locked: true) 
        log_lock_activity("lock_protocol_step_#{content_block_type}") if @element.saved_change_to_locked?
      end
      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def unlock
      ActiveRecord::Base.transaction do
        @element.update!(locked: false)
        log_lock_activity("unlock_protocol_step_#{content_block_type}") if @element.saved_change_to_locked?
      end
      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def archive
      ActiveRecord::Base.transaction do
        @element.archive!(current_user)
        log_archive_activity
      end
      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def restore
      ActiveRecord::Base.transaction do
        @element.restore!(current_user)
        log_restore_activity
      end
      restore_response
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    private

    def load_step_and_protocol
      @step = Step.find_by(id: params[:step_id])
      return render_404 unless @step

      @protocol = @step.protocol
    end

    def check_manage_step_permissions
      render_403 unless can_manage_step?(@step)
    end

    def check_lock_permissions
      render_403
    end

    def check_unlock_permissions
      render_403
    end

    def log_archive_activity
      raise NotImplementedError
    end

    def log_restore_activity
      raise NotImplementedError
    end

    def content_block_type
      raise NotImplementedError
    end

    def restore_response
      head :ok
    end

    def create_in_step!(step, new_orderable)
      ActiveRecord::Base.transaction do
        new_orderable.save!

        step.step_orderable_elements.create!(
          position: step.next_element_position,
          orderable: new_orderable
        )
      end
    end

    def render_step_orderable_element(orderable)
      render json: orderable, serializer: StepOrderableElementSerializer, user: current_user
    end

    def log_step_activity(element_type_of, message_items)
      message_items[:my_module] = @protocol.my_module.id if @protocol.in_module?

      Activities::CreateActivityService.call(
        activity_type: "#{@step.protocol.in_module? ? 'task_step_' : 'protocol_step_'}#{element_type_of}",
        owner: current_user,
        team: @protocol.team,
        project: @protocol.in_module? ? @protocol.my_module.project : nil,
        subject: @protocol,
        message_items: {
          step: @step.id,
          step_position: {
            id: @step.id,
            value_for: 'position_plus_one'
          }
        }.merge(message_items)
      )
    end

    def log_step_restore_activity(type_of, message_items)
      Activities::CreateActivityService.call(
        activity_type: type_of,
        owner: current_user,
        team: @protocol.team,
        project: @protocol.my_module.project,
        subject: @protocol,
        message_items: message_items
      )
    end

    def log_lock_activity(activity_type)
      Activities::CreateActivityService.call(
        activity_type: activity_type,
        owner: current_user,
        team: @protocol.team,
        subject: @protocol,
        message_items: {
          step: @step.id,
          step_position: {
            id: @step.id,
            value_for: 'position_plus_one'
          }
        }
      )
    end
  end
end
