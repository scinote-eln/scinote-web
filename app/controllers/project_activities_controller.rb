class ProjectActivitiesController < ApplicationController
  before_action :load_vars, only: [ :index ]
  before_action :check_view_permissions, only: [ :index ]

  def index
    @activities = @project.last_activities

    respond_to do |format|
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "index.html.erb"
          })
        }
      }
    end
  end

  private

  def load_vars
    @project = Project.find_by_id(params[:project_id])
    unless @project
      render_404
    end
  end

  def check_view_permissions
    render_403 unless can_read_project?(@project)
  end

end
