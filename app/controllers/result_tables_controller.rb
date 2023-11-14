class ResultTablesController < ApplicationController
  include ResultsHelper

  before_action :load_vars, only: [:edit, :update, :download]
  before_action :convert_contents_to_utf8, only: [:update]

  before_action :check_manage_permissions, only: %i(edit update)
  before_action :check_archive_permissions, only: [:update]
  before_action :check_view_permissions, except: %i(edit update)

  def edit
    render json: {
      html: render_to_string({ partial: 'edit', formats: :html })
    }, status: :ok
  end

  def update
    update_params = result_params
    @result.last_modified_by = current_user
    @result.table.last_modified_by = current_user
    @result.table.team = current_team
    @result.assign_attributes(update_params)
    @result.table.metadata = JSON.parse(update_params[:table_attributes][:metadata]) if update_params[:table_attributes]
    flash_success = t("result_tables.update.success_flash",
      module: @my_module.name)
    if @result.archived_changed?(from: false, to: true)
      saved = @result.archive(current_user)
      flash_success = t("result_tables.archive.success_flash",
        module: @my_module.name)
      if saved
        log_activity(:archive_result)
      end
    elsif @result.archived_changed?(from: true, to: false)
      render_403
    else
      saved = @result.save

      if saved then
        log_activity(:edit_result)
      end
    end
    respond_to do |format|
      if saved
        format.html {
          flash[:success] = flash_success
          redirect_to results_my_module_path(@my_module)
        }
        format.json {
          render json: {
            html: render_to_string(
              partial: 'my_modules/result',
              locals: { result: @result },
              formats: :html
            )
          }, status: :ok
        }
      else
        format.json {
          render json: @result.errors, status: :bad_request
        }
      end
    end
  end

  def download
    _ = JSON.parse @result_table.table.contents
    @table_data = _["data"] || []
    data = render_to_string partial: 'download'
    send_data data, filename: @result_table.result.name + '.txt',
      type: 'plain/text'
  end

  private

  def load_vars
    @result_table = ResultTable.find_by_id(params[:id])

    if @result_table
      @result = @result_table.result
      @my_module = @result.my_module
    else
      render_404
    end
  end

  def convert_contents_to_utf8
    if params.include? :result and
      params[:result].include? :table_attributes and
      params[:result][:table_attributes].include? :contents then
      params[:result][:table_attributes][:contents] =
        params[:result][:table_attributes][:contents].encode(Encoding::UTF_8).force_encoding(Encoding::UTF_8)
    end
  end

  def check_manage_permissions
    render_403 unless can_manage_result?(@result)
  end

  def check_archive_permissions
    if result_params[:archived].to_s != '' && !can_manage_result?(@result)
      render_403
    end
  end

  def check_view_permissions
    render_403 unless can_read_result?(@result)
  end

  def result_params
    params.require(:result).permit(
      :name, :archived,
      table_attributes: [
        :id,
        :contents,
        :metadata
      ]
    )
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @result,
            team: @my_module.team,
            project: @my_module.project,
            message_items: {
              result: @result.id,
              type_of_result: t('activities.result_type.table')
            })
  end
end
