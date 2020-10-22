# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @my_module_status_flows = MyModuleStatusFlow.all.preload(my_module_statuses: :my_module_status_consequences)
  end
end
