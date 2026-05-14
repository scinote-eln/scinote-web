# frozen_string_literal: true

module StepElements
  class ChecklistsController < BaseController
    include ApplicationHelper
    include StepsActions

    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :check_manage_step_permissions, only: %i(create move_targets)
    before_action :load_checklist, only: %i(update destroy duplicate move archive restore)
    before_action :check_manage_permissions, except: %i(create archive restore destroy move_targets)
    before_action :check_archive_permissions, only: :archive
    before_action :check_restore_permissions, only: :restore
    before_action :check_delete_permissions, only: :destroy
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def create
      checklist = @step.checklists.build(
        name: t('protocols.steps.checklist.default_name', position: @step.checklists.length + 1),
        created_by: current_user
      )
      ActiveRecord::Base.transaction do
        create_in_step!(@step, checklist)
        log_step_activity(:checklist_added, { checklist_name: checklist.name })
        checklist_name_annotation(@step, checklist)
      end
      render_step_orderable_element(checklist)
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def update
      old_name = @checklist.name
      ActiveRecord::Base.transaction do
        @checklist.update!(checklist_params.merge(last_modified_by: current_user))
        log_step_activity(:checklist_edited, { checklist_name: @checklist.name })
        checklist_name_annotation(@step, @checklist, old_name)
      end

      render json: @checklist, serializer: ChecklistSerializer, user: current_user
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def move
      target = @protocol.steps.find_by(id: params[:target_id])
      ActiveRecord::Base.transaction do
        @checklist.update!(step: target)
        @checklist.step_orderable_element.update!(step: target, position: target.next_element_position)
        @step.normalize_elements_position

        log_step_activity(
          :checklist_moved,
          {
            user: current_user.id,
            checklist_name: @checklist.name,
            step_position_original: @step.position + 1,
            step_original: @step.id,
            step_position_destination: target.position + 1,
            step_destination: target.id
          }
        )

        render json: @checklist, serializer: ChecklistSerializer, user: current_user
      rescue ActiveRecord::RecordInvalid
        render json: @checklist.errors, status: :unprocessable_entity
      end
    end

    def destroy
      if @checklist.destroy
        log_step_activity(:checklist_deleted, { checklist_name: @checklist.name })
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        position = @checklist.step_orderable_element.position
        @step.step_orderable_elements.where('position > ?', position).order(position: :desc).each do |element|
          element.update(position: element.position + 1)
        end
        @checklist.name += ' (1)'
        new_checklist = @checklist.duplicate(@step, current_user, position + 1)
        log_step_activity(:checklist_duplicated, { checklist_name: @checklist.name })
        render_step_orderable_element(new_checklist)
      end
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def archive
      ActiveRecord::Base.transaction do
        @checklist.archive!(current_user)
        log_step_activity(:checklist_archived, { checklist_name: @checklist.name })
      end

      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def restore
      ActiveRecord::Base.transaction do
        @checklist.restore!(current_user)
        log_step_restore_activity(:task_step_checklist_restored, { checklist_name: @checklist.name })
      end

      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    private

    def checklist_params
      params.permit(:name, :text)
    end

    def load_checklist
      @checklist = @step.checklists.find_by(id: params[:id])
      return render_404 unless @checklist
    end

    def check_manage_permissions
      render_403 unless can_manage_step_checklist?(@checklist)
    end

    def check_archive_permissions
      render_403 unless can_archive_step_checklist?(@checklist)
    end

    def check_restore_permissions
      render_403 unless can_restore_step_checklist?(@checklist)
    end

    def check_delete_permissions
      render_403 unless can_delete_step_checklist?(@checklist)
    end
  end
end
