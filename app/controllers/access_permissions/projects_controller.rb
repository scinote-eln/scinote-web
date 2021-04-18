# frozen_string_literal: true

module AccessPermissions
  class ProjectsController < ApplicationController
    before_action :set_project
    before_action :check_manage_permissions

    def edit

    end

    private

    def set_project
      @project = Project.find_by(id: params[:id])

      render_404 unless @project
    end

    def check_manage_permissions
      render_403 unless can_manage_project?(@project)
    end
  end
end
