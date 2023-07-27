# frozen_string_literal: true

class MyModuleStatusFlowController < ApplicationController
  before_action :load_my_module
  before_action :check_view_permissions

  def show
    my_module_statuses = @my_module.my_module_status_flow
                                   .my_module_statuses
                                   .preload(:my_module_status_implications, next_status: :my_module_status_conditions)
                                   .sort_by_position
    render json: { html: render_to_string(partial: 'my_modules/modals/status_flow_modal_body',
                                          locals: { my_module_statuses: my_module_statuses }) }
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])
    render_404 unless @my_module
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end
end
