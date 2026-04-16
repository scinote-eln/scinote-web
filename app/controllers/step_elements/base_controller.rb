# frozen_string_literal: true

module StepElements
  class BaseController < ApplicationController
    before_action :load_step_and_protocol

    def move_targets
      render json: { targets: @protocol.steps.active.order(:position).where.not(id: @step.id).map { |i| [i.id, i.name] } }
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

    def create_in_step!(step, new_orderable)
      ActiveRecord::Base.transaction do
        new_orderable.save!

        step.step_orderable_elements.create!(
          position: step.next_element_position,
          orderable: new_orderable
        )
      end
    end

    def archive_element!(step, orderable_element)
      ActiveRecord::Base.transaction do
        orderable_element.position = nil
        orderable_element.archive!(current_user)
        step.normalize_elements_position

        case orderable_element.orderable
        when StepText
          log_step_activity(:text_archived, { text_name: orderable_element.orderable.name })
        when StepTable
          log_step_activity(:table_archived, { table_name: orderable_element.orderable.table.name })
        when Checklist
          log_step_activity(:checklist_archived, { checklist_name: orderable_element.orderable.name })
        when FormResponse
          log_step_activity(:form_archived, { form: orderable_element.orderable.form.id })
        end
      end
    end

    def restore_element!(step, orderable_element)
      ActiveRecord::Base.transaction do
        orderable_element.position = step.next_element_position
        orderable_element.restore!(current_user)

        case orderable_element.orderable
        when StepText
          log_step_restore_activity(:task_step_text_restored, { text_name: orderable_element.orderable.name })
        when StepTable
          log_step_restore_activity(:task_step_table_restored, { table_name: orderable_element.orderable.table.name })
        when Checklist
          log_step_restore_activity(:task_step_checklist_restored, { checklist_name: orderable_element.orderable.name })
        when FormResponse
          log_step_restore_activity(:task_step_form_restored, { form: orderable_element.orderable.form.id })
        end
      end
    end

    def render_step_orderable_element(orderable)
      step_orderable_element = orderable.step_orderable_element
      render json: step_orderable_element, serializer: StepOrderableElementSerializer, user: current_user
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
  end
end
