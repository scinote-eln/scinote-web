# frozen_string_literal: true

module ResultElements
  class BaseController < ApplicationController
    before_action :load_result_and_parent

    def move_targets
      targets = @parent.results
                       .active
                       .where.not(id: @result.id)
                       .map { |i| [i.id, i.name] }
      render json: { targets: targets }
    end

    def lock
      ActiveRecord::Base.transaction do
        @element.update!(locked: true)
        log_lock_activity("lock_result_template_#{content_block_type}") if @element.saved_change_to_locked?
      end
      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def unlock
      ActiveRecord::Base.transaction do
        @element.update!(locked: false)
        log_lock_activity("unlock_result_template_#{content_block_type}") if @element.saved_change_to_locked?
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

    def load_result_and_parent
      @result = ResultBase.find_by(id: params[:result_id] || params[:result_template_id])
      return render_404 unless @result

      @parent = @result.parent

      current_team_switch(@parent.team) if current_team != @parent.team
    end

    def check_manage_result_permissions
      render_403 unless can_manage_result?(@result)
    end

    def check_lock_permissions
      render_403
    end

    def check_unlock_permissions
      render_403
    end

    def log_archive_activity; end

    def log_restore_activity; end

    def content_block_type
      raise NotImplementedError
    end

    def restore_response
      head :ok
    end

    def create_in_result!(result, new_orderable)
      ActiveRecord::Base.transaction do
        new_orderable.save!

        result_orderable_element = ResultOrderableElement.new(
          position: result.result_orderable_elements.length,
          orderable: new_orderable
        )

        result_orderable_element.result_id = result.id
        result_orderable_element.save!
      end
    end

    def render_result_orderable_element(orderable)
      render json: orderable, serializer: ResultOrderableElementSerializer, user: current_user
    end

    def log_result_activity(element_type_of, message_items)
      model_key = @result.class.model_name.param_key
      key = @parent.is_a?(MyModule) ? :my_module : :protocol
      message_items[key] = @parent.id
      message_items[model_key] = @result.id
      Activities::CreateActivityService.call(
        activity_type: :"#{model_key}_#{element_type_of}",
        owner: current_user,
        team: @parent.team,
        subject: @result,
        project: @parent.is_a?(MyModule) ? @parent.experiment.project : nil,
        message_items: message_items
      )
    end

    def log_lock_activity(activity_type)
      Activities::CreateActivityService.call(
        activity_type: activity_type,
        owner: current_user,
        team: @parent.team,
        subject: @result,
        message_items: {
          result_template: @result.id,
          protocol: @parent.id
        }
      )
    end
  end
end
