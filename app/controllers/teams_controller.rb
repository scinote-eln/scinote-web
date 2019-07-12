class TeamsController < ApplicationController
  before_action :load_vars, only: %i(parse_sheet export_projects export_projects_modal)
  before_action :check_export_projects_permissions, only: %i(export_projects_modal export_projects)

  def parse_sheet
    session[:return_to] ||= request.referer

    unless import_params[:file]
      return parse_sheet_error(t('teams.parse_sheet.errors.no_file_selected'))
    end
    if import_params[:file].size > Rails.configuration.x.file_max_size_mb.megabytes
      error = t('general.file.size_exceeded',
                file_size: Rails.configuration.x.file_max_size_mb)
      return parse_sheet_error(error)
    end

    begin
      sheet = SpreadsheetParser.open_spreadsheet(import_params[:file])
      @header, @columns = SpreadsheetParser.first_two_rows(sheet)

      if @header.empty? || @columns.empty?
        return parse_sheet_error(t('teams.parse_sheet.errors.empty_file'))
      end

      # Fill in fields for dropdown
      @available_fields = @team.get_available_sample_fields
      # Truncate long fields
      @available_fields.update(@available_fields) do |_k, v|
        v.truncate(Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
      end

      # Save file for next step (importing)
      @temp_file = TempFile.new(
        session_id: session.id,
        file: import_params[:file]
      )

      if @temp_file.save
        TempFile.destroy_obsolete(@temp_file.id)
        respond_to do |format|
          format.json do
            render json: {
              html: render_to_string(
                partial: 'samples/parse_samples_modal.html.erb'
              )
            }
          end
        end
      else
        return parse_sheet_error(
          t('teams.parse_sheet.errors.temp_file_failure')
        )
      end
    rescue ArgumentError, CSV::MalformedCSVError
      return parse_sheet_error(t('teams.parse_sheet.errors.invalid_file',
                                 encoding: ''.encoding))
    rescue TypeError
      return parse_sheet_error(t('teams.parse_sheet.errors.invalid_extension'))
    end
  end

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

  def parse_sheet_error(error)
    respond_to do |format|
      format.html do
        flash[:alert] = error
        session[:return_to] ||= request.referer
        redirect_to session.delete(:return_to)
      end
      format.json do
        render json: { message: error },
          status: :unprocessable_entity
      end
    end
  end

  def load_vars
    @team = Team.find_by_id(params[:id])

    unless @team
      render_404
    end
  end

  def import_params
    params.permit(:id, :file, :file_id, mappings: {}).to_h
  end

  def export_params
    params.permit(sample_ids: [], header_ids: []).to_h
  end

  def export_projects_params
    params.permit(:id, project_ids: []).to_h
  end

  def check_create_samples_permissions
    render_403 unless can_create_samples?(@team)
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

  def generate_samples_zip
    zip = ZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
      @team.to_csv(
        Sample.where(id: export_params[:sample_ids]),
        export_params[:header_ids]
      ),
      :samples
    )
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
