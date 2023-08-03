# frozen_string_literal: true

class ResultsController < ApplicationController
  before_action :load_vars, only: :destroy
  before_action :check_destroy_permissions, only: :destroy

  def index
    @my_module = MyModule.readable_by_user(current_user).find(params[:my_module_id])

    respond_to do |format|
      format.json do
        # API endpoint
        render(
          json: @my_module.results,
          formats: :json
        )
      end

      format.html do
        # Main view
        @experiment = @my_module.experiment
        @project = @experiment.project
        render(:index, formats: :html)
      end
    end
  end

  def destroy
    result_type = if @result.is_text
                    t('activities.result_type.text')
                  elsif @result.is_table
                    t('activities.result_type.table')
                  elsif @result.is_asset
                    t('activities.result_type.asset')
                  end
    Activities::CreateActivityService
      .call(activity_type: :destroy_result,
            owner: current_user,
            subject: @result,
            team: @my_module.team,
            project: @my_module.project,
            message_items: { result: @result.id,
                             type_of_result: result_type })
    flash[:success] = t('my_modules.module_archive.delete_flash',
                        result: @result.name,
                        module: @my_module.name)
    @result.destroy
    redirect_to archive_my_module_path(@my_module)
  end

  private

  def load_vars
    @result = Result.find_by_id(params[:id])

    return render_403 unless @result

    @my_module = @result.my_module
  end

  def check_destroy_permissions
    render_403 unless can_delete_result?(@result)
  end
end
