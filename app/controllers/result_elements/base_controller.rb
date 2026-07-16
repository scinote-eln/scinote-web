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
      @element.update!(locked: true)
      head :ok
    rescue ActiveRecord::RecordInvalid
      head :unprocessable_entity
    end

    def unlock
      @element.update!(locked: false)
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
  end
end
