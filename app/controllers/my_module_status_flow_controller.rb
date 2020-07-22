# frozen_string_literal: true

class MyModuleStatusFlowController < ApplicationController
  def show
    my_module_status_flow = [
      { name: 'Not started', color: '#406d86', current_status: false, status_comment: nil },
      { name: 'In progress', color: '#0065ff', current_status: true, status_comment: nil },
      { name: 'Completed', color: '#00b900', current_status: false, status_comment: nil },
      { name: 'In review', color: '#ff4500', current_status: false, status_comment: 'Requiers signature' },
      { name: 'Done', color: '#0ecdc0', current_status: false, status_comment: nil }
    ]

    render json: { html: render_to_string(partial: 'my_modules/modals/status_flow_modal_body.html.erb', locals: { status_flow: my_module_status_flow }) }
  end
end
