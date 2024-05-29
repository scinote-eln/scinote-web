# frozen_string_literal: true

class DashboardsController < ApplicationController
  include TeamsHelper

  before_action :switch_team_with_param, only: :show

  def show
    @my_module_status_flows = MyModuleStatusFlow.all.preload(my_module_statuses: :my_module_status_consequences)
  end
end
