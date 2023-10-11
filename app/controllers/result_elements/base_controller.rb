# frozen_string_literal: true

module ResultElements
  class BaseController < ApplicationController
    before_action :load_result_and_my_module
    before_action :check_manage_permissions

    def move_targets
      targets = @my_module.results
                          .active
                          .where.not(id: @result.id)
                          .map { |i| [i.id, i.name] }
      render json: { targets: targets }
    end

    private

    def load_result_and_my_module
      @result = Result.find_by(id: params[:result_id])
      return render_404 unless @result

      @my_module = @result.my_module
    end

    def check_manage_permissions
      render_403 unless can_manage_my_module?(@my_module)
    end

    def create_in_result!(result, new_orderable)
      ActiveRecord::Base.transaction do
        new_orderable.save!

        result.result_orderable_elements.create!(
          position: result.result_orderable_elements.length,
          orderable: new_orderable
        )
      end
    end

    def render_result_orderable_element(orderable)
      result_orderable_element = orderable.result_orderable_element
      render json: result_orderable_element, serializer: ResultOrderableElementSerializer, user: current_user
    end

    def log_result_activity(element_type_of, message_items)
      message_items[:my_module] = @my_module.id

      Activities::CreateActivityService.call(
        activity_type: element_type_of,
        owner: current_user,
        team: @my_module.team,
        subject: @result,
        project: @my_module.experiment.project,
        message_items: {
          result: @result.id
        }.merge(message_items)
      )
    end
  end
end
