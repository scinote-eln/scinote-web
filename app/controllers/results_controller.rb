class ResultsController < ApplicationController
  before_action :load_vars
  before_action :check_destroy_permissions

  def destroy
    act_log = t('my_modules.module_archive.table_log',
                user: current_user.name,
                result: @result.name,
                date: l(Time.current, format: :full_date))
    act_log = t('my_modules.module_archive.text_log',
                user: current_user.name,
                result: @result.name,
                date: l(Time.current, format: :full_date)) if @result.is_text
    act_log = t('my_modules.module_archive.asset_log',
                user: current_user.name,
                result: @result.name,
                date: l(Time.current, format: :full_date)) if @result.is_asset

    Activity.create(
      type_of: :destroy_result,
      user: current_user,
      project: @my_module.experiment.project,
      experiment: @my_module.experiment,
      my_module: @my_module,
      message: act_log
    )
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
    render_403 unless can_manage_result?(@result)
  end
end
