class TeamsController < ApplicationController
  before_action :load_vars, only: %i(export_projects
                                     export_projects_modal)

  before_action :check_export_projects_permissions,
                only: %i(export_projects_modal export_projects)

  def export_projects
    if current_user.has_available_exports?
      current_user.increase_daily_exports_counter!

      generate_export_projects_zip

      Activities::CreateActivityService
        .call(activity_type: :export_projects,
              owner: current_user,
              subject: @team,
              team: @team,
              message_items: {
                team: @team.id,
                projects: @exp_projects.map(&:name).join(', ')
              })

      render json: {
        flash: t('projects.export_projects.success_flash')
      }, status: :ok
    end
  end

  def export_projects_modal
    if @exp_projects.present?
      if current_user.has_available_exports?
        render json: {
          html: render_to_string(
            partial: 'projects/export/modal.html.erb',
            locals: { num_projects: @exp_projects.size,
                      limit: TeamZipExport.exports_limit,
                      num_of_requests_left: current_user.exports_left - 1 }
          ),
          title: t('projects.export_projects.modal_title')
        }
      else
        render json: {
          html: render_to_string(
            partial: 'projects/export/error.html.erb',
            locals: { limit: TeamZipExport.exports_limit }
          ),
          title: t('projects.export_projects.error_title'),
          status: 'error'
        }
      end
    end
  end

  def routing_error(error = 'Routing error', status = :not_found, exception=nil)
    redirect_to root_path
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:id])

    unless @team
      render_404
    end
  end

  def export_projects_params
    params.permit(:id, project_ids: []).to_h
  end

  def check_export_projects_permissions
    render_403 unless can_read_team?(@team)

    if export_projects_params[:project_ids]
      @exp_projects = Project.where(id: export_projects_params[:project_ids])
      @exp_projects.each do |project|
        render_403 unless can_export_project?(current_user, project)
      end
    end
  end

  def generate_export_projects_zip
    ids = @exp_projects.where(team_id: @team).index_by(&:id)

    options = { team: @team }
    zip = TeamZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
      ids,
      :teams,
      options
    )
    ids
  end
end
