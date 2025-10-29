# frozen_string_literal: true

module ResultElements
  class BaseController < ApplicationController
    before_action :load_result_and_parent
    before_action :check_manage_permissions

    def move_targets
      targets = @parent.results
                       .active
                       .where.not(id: @result.id)
                       .map { |i| [i.id, i.name] }
      render json: { targets: targets }
    end

    private

    def load_result_and_parent
      @result = ResultBase.find_by(id: params[:result_id] || params[:result_template_id])
      return render_404 unless @result

      @parent = @result.parent

      current_team_switch(@parent.team) if current_team != @parent.team
    end

    def check_manage_permissions
      render_403 unless can_manage_result?(@result)
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
      result_orderable_element = orderable.result_orderable_element
      render json: result_orderable_element, serializer: ResultOrderableElementSerializer, user: current_user
    end

    def log_result_activity(element_type_of, message_items)
      if @parent.is_a?(MyModule)
        message_items[:my_module] = @parent.id
        project = @parent.experiment.project
      else
        return # TODO: - SCI-12365
      end

      Activities::CreateActivityService.call(
        activity_type: element_type_of,
        owner: current_user,
        team: @parent.team,
        subject: @result,
        project: project,
        message_items: {
          result: @result.id
        }.merge(message_items)
      )
    end
  end
end
