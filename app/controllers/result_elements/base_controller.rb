# frozen_string_literal: true

module ResultElements
  class BaseController < ApplicationController
    before_action :load_result_and_my_module
    before_action :check_manage_permissions

    def move_targets
      render json: { targets: @my_module.results.where.not(id: @result.id).map{ |i| [i.id, i.name] } }
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
      # TODO
      #message_items[:my_module] = @protocol.my_module.id if @protocol.in_module?
      #Activities::CreateActivityService.call(
      #  activity_type: "#{!@step.protocol.in_module? ? 'protocol_step_' : 'task_step_'}#{element_type_of}",
      #  owner: current_user,
      #  team: @protocol.team,
      #  project: @protocol.in_module? ? @protocol.my_module.project : nil,
      #  subject: @protocol,
      #  message_items: {
      #    step: @step.id,
      #    step_position: {
      #      id: @step.id,
      #      value_for: 'position_plus_one'
      #    },
      #  }.merge(message_items)
      #)
    end
  end
end
