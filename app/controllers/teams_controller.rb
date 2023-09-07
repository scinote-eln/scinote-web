# frozen_string_literal: true

class TeamsController < ApplicationController
  include ProjectsHelper
  include CardsViewHelper
  attr_reader :current_folder
  helper_method :current_folder

  before_action :load_vars, only: %i(sidebar export_projects export_projects_modal
                                     disable_tasks_sharing_modal shared_tasks_toggle)
  before_action :load_current_folder, only: :sidebar
  before_action :check_read_permissions, except: :view_type
  before_action :check_export_projects_permissions, only: %i(export_projects_modal export_projects)

  def sidebar
    render json: {
      html: render_to_string(
        partial: 'shared/sidebar/projects',
        locals: { team: current_team, sort: params[:sort] },
        formats: :html
      )
    }
  end

  def export_projects
    if current_user.has_available_exports?
      current_user.increase_daily_exports_counter!
      TeamZipExportJob.perform_later(
        user_id: current_user.id,
        params: {
          team_id: @team.id,
          project_ids: @exp_projects.collect(&:id)
        }
      )
      log_activity(:export_projects,
                   team: @team.id,
                   projects: @exp_projects.map(&:name).join(', '))

      render json: { flash: t('projects.export_projects.success_flash') }
    end
  end

  def export_projects_modal
    if @exp_projects.present?
      if current_user.has_available_exports?
        render json: {
          html: render_to_string(
            partial: 'projects/export/modal',
            locals: { num_projects: @exp_projects.size,
                      limit: TeamZipExport.exports_limit,
                      num_of_requests_left: current_user.exports_left - 1 },
            formats: :html
          ),
          title: t('projects.export_projects.modal_title')
        }
      else
        render json: {
          html: render_to_string(
            partial: 'projects/export/error',
            locals: { limit: TeamZipExport.exports_limit },
            formats: :html
          ),
          title: t('projects.export_projects.error_title'),
          status: 'error'
        }
      end
    else
      render json: { flash: I18n.t('projects.export_projects.zero_projects_flash') }, status: :unprocessable_entity
    end
  end

  def disable_tasks_sharing_modal
    render json: {
      html: render_to_string(
        partial: 'users/settings/teams/destroy_tasks_sharing_modal',
        locals: {},
        formats: :html
      )
    }
  end

  def shared_tasks_toggle
    return render_403 unless can_manage_team?(@team)

    @team.toggle!(:shareable_links_enabled)

    if @team.shareable_links_enabled?
      log_activity(:team_sharing_tasks_enabled,
                   team: @team.id,
                   user: current_user.id)
    else
      log_activity(:team_sharing_tasks_disabled,
                   team: @team.id,
                   user: current_user.id)
    end
  end

  def routing_error(error = 'Routing error', status = :not_found, exception=nil)
    redirect_to root_path
  end

  def view_type
    view_state = current_team.current_view_state(current_user)
    view_state.state['projects']['view_type'] = view_type_params
    view_state.save!

    render json: { cards_view_type_class: cards_view_type_class(view_type_params) }, status: :ok
  end

  private

  def load_vars
    @team = current_user.teams.find_by(id: params[:id])
    render_404 unless @team
  end

  def export_projects_params
    params.permit(:id, project_ids: [], project_folder_ids: [])
  end

  def view_type_params
    params.require(:projects).require(:view_type)
  end

  def check_read_permissions
    render_403 unless can_read_team?(@team)
  end

  def load_current_folder
    if current_team && params[:project_folder_id].present?
      @current_folder = current_team.project_folders.find_by(id: params[:project_folder_id])
    end
  end

  def check_export_projects_permissions
    @exp_projects = []
    if export_projects_params[:project_ids]
      @exp_projects = @team.projects.where(id: export_projects_params[:project_ids]).to_a
    end
    if export_projects_params[:project_folder_ids]
      folders = @team.project_folders.where(id: export_projects_params[:project_folder_ids])
      folders.each do |folder|
        @exp_projects += folder.inner_projects.visible_to(current_user, @team)
      end
    end

    @exp_projects.each do |project|
      return render_403 unless can_export_project?(current_user, project)
    end
  end

  def log_activity(type_of, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @team,
            team: @team,
            message_items: message_items)
  end
end
