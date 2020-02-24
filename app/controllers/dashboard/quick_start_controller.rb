# frozen_string_literal: true

module Dashboard
  class QuickStartController < ApplicationController
    def create_task
      my_module = CreateMyModule.new(current_user, current_team, my_module_params).call
      if my_module
        render json: { my_module_path: protocols_my_module_path(my_module) }
      else
        render json: {}, status: :unprocessable_entity
      end
    end

    private

    def my_module_params
      params.permit(:project_id, :project_name, :experiment_id, :experiment_name)
    end
  end
end
