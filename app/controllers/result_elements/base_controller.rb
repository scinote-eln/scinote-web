# frozen_string_literal: true

module ResultElements
  class BaseController < ApplicationController
    before_action :load_result_and_my_module
    before_action :check_manage_permissions

    def move_targets
      targets = @object.results
                       .active
                       .where.not(id: @result.id)
                       .map { |i| [i.id, i.name] }
      render json: { targets: targets }
    end

    private

    def load_result_and_my_module
      @result = if params[:result_template_id].present?
                  ResultTemplate.find_by(id: params[:result_template_id])
                else
                  Result.find_by(id: params[:result_id])
                end
      return render_404 unless @result

      @object = @result.my_module if @result.is_a?(Result)
      @object = @result.protocol if @result.is_a?(ResultTemplate)

      current_team_switch(@object.team) if current_team != @object.team
    end

    def check_manage_permissions
      render_403 if @object.is_a?(MyModule) && !can_manage_my_module?(@object)
      render_403 if @object.is_a?(Protocol) && !can_manage_protocol_draft_in_repository?(@object)
    end

    def create_in_result!(result, new_orderable)
      ActiveRecord::Base.transaction do
        new_orderable.save!

        result_orderable_element = ResultOrderableElement.new(
          position: result.result_orderable_elements.length,
          orderable: new_orderable
        )

        if result.is_a?(ResultTemplate)
          result_orderable_element.result_template = result
        else
          result_orderable_element.result = result
        end

        result_orderable_element.save!
      end
    end

    def render_result_orderable_element(orderable)
      result_orderable_element = orderable.result_orderable_element
      render json: result_orderable_element, serializer: ResultOrderableElementSerializer, user: current_user
    end

    def log_result_activity(element_type_of, message_items)
      message_items[:my_module] = @object.id

      Activities::CreateActivityService.call(
        activity_type: element_type_of,
        owner: current_user,
        team: @object.team,
        subject: @result,
        project: @object.experiment.project,
        message_items: {
          result: @result.id
        }.merge(message_items)
      )
    end
  end
end
