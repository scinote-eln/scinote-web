class ResultTablesController < ApplicationController
  include ResultsHelper

  before_action :load_vars, only: [:edit, :update, :download]
  before_action :load_vars_nested, only: [:new, :create]
  before_action :convert_contents_to_utf8, only: [:create, :update]

  before_action :check_manage_permissions, only: %i(new create edit update)
  before_action :check_archive_permissions, only: [:update]

  def new
    @table = Table.new
    @result = Result.new(
      user: current_user,
      my_module: @my_module,
      table: @table
    )

    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "new.html.erb"
          })
        }, status: :ok
      }
    end
  end

  def create
    @table = Table.new(result_params[:table_attributes])
    @table.created_by = current_user
    @table.team = current_team
    @table.last_modified_by = current_user
    @table.name = nil
    @result = Result.new(
      user: current_user,
      my_module: @my_module,
      name: result_params[:name],
      table: @table
    )
    @result.last_modified_by = current_user

    respond_to do |format|
      if (@result.save and @table.save) then
        log_activity(:add_result)

        format.html {
          flash[:success] = t(
            "result_tables.create.success_flash",
            module: @my_module.name)
          redirect_to results_my_module_path(@my_module)
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: "my_modules/result.html.erb", locals: {result: @result}
            })
          }, status: :ok
        }
      else
        format.json {
          render json: @result.errors, status: :bad_request
        }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "edit.html.erb"
          })
        }, status: :ok
      }
    end
  end

  def update
    update_params = result_params
    @result.last_modified_by = current_user
    @result.table.last_modified_by = current_user
    @result.table.team = current_team
    @result.assign_attributes(update_params)
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
            html: render_to_string({
              partial: "my_modules/result.html.erb", locals: {result: @result}
            })
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
    data = render_to_string partial: 'download.txt.erb'
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

  def load_vars_nested
    @my_module = MyModule.find_by_id(params[:my_module_id])

    unless @my_module
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
    render_403 unless can_manage_module?(@my_module)
  end

  def check_archive_permissions
    if result_params[:archived].to_s != '' && !can_manage_result?(@result)
      render_403
    end
  end

  def result_params
    params.require(:result).permit(
      :name, :archived,
      table_attributes: [
        :id,
        :contents
      ]
    )
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @result,
            team: @my_module.experiment.project.team,
            project: @my_module.experiment.project,
            message_items: {
              result: @result.id,
              type_of_result: t('activities.result_type.table')
            })
  end
end
