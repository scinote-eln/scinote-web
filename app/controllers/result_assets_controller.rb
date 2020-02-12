class ResultAssetsController < ApplicationController
  include ResultsHelper

  before_action :load_vars, only: [:edit, :update, :download]
  before_action :load_vars_nested, only: [:new, :create]

  before_action :check_manage_permissions, only: %i(new create edit update)
  before_action :check_archive_permissions, only: [:update]

  def new
    @asset = Asset.new
    @result = Result.new(
      user: current_user,
      my_module: @my_module,
      asset: @asset
    )

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(partial: 'new.html.erb')
        }, status: :ok
      end
    end
  end

  def create
    obj = create_multiple_results
    respond_to do |format|
      if obj.fetch(:status)
        format.html do
          flash[:success] = t('result_assets.create.success_flash',
                              module: @my_module.name)
          redirect_to results_my_module_path(@my_module)
        end
        format.json do
          render json: {
            html: render_to_string(
              partial: 'my_modules/results.html.erb',
                       locals: { results: obj.fetch(:results) }
            )
          }, status: :ok
        end
      else
        flash[:error] = t('result_assets.error_flash')
        format.json do
          render json: {}, status: :bad_request
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(partial: 'edit.html.erb')
        }, status: :ok
      end
    end
  end

  def update
    success_flash = nil
    saved = false

    @result.transaction do
      update_params = result_params.reject { |_, v| v.blank? }
      previous_size = @result.space_taken

      if update_params.dig(:asset_attributes, :signed_blob_id)
        @result.asset.last_modified_by = current_user
        @result.asset.update(file: update_params[:asset_attributes][:signed_blob_id])
        update_params.delete(:asset_attributes)
      end

      @result.last_modified_by = current_user
      @result.assign_attributes(update_params)
      success_flash = t('result_assets.update.success_flash', module: @my_module.name)

      if @result.archived_changed?(from: false, to: true)
        if @result.asset.locked?
          @result.errors.add(:asset_attributes, t('result_assets.archive.error_flash'))
          raise ActiveRecord:: Rollback
        end

        saved = @result.archive(current_user)
        success_flash = t('result_assets.archive.success_flash', module: @my_module.name)
        log_activity(:archive_result) if saved
      elsif @result.archived_changed?(from: true, to: false)
        @result.errors.add(:asset_attributes, t('result_assets.archive.error_flash'))
        raise ActiveRecord:: Rollback
      else
        if @result.asset.locked?
          @result.errors.add(:asset_attributes, t('result_assets.edit.locked_file_error'))
          raise ActiveRecord:: Rollback
        end
        # Asset (file) and/or name has been changed
        asset_changed = @result.asset.changed?
        saved = @result.save

        if saved
          # Release team's space taken due to
          # previous asset being removed
          team = @result.my_module.experiment.project.team
          team.release_space(previous_size) if asset_changed
          team.save

          # Post process new file if neccesary
          @result.asset.post_process_file(team) if asset_changed && @result.asset.present?

          log_activity(:edit_result)
        end
      end
    end

    respond_to do |format|
      if saved
        format.html do
          flash[:success] = success_flash
          redirect_to results_my_module_path(@my_module)
        end
        format.json do
          render json: {
            html: render_to_string(
              partial: 'my_modules/result.html.erb', locals: { result: @result }
            )
          }, status: :ok
        end
      else
        format.json do
          render json: {
            status: :error,
            errors: @result.errors
          }, status: :bad_request
        end
      end
    end
  end

  private

  def load_vars
    @result_asset = ResultAsset.find_by_id(params[:id])

    if @result_asset
      @result = @result_asset.result
      @my_module = @result.my_module
    else
      render_404
    end
  end

  def load_vars_nested
    @my_module = MyModule.find_by_id(params[:my_module_id])
    render_404 unless @my_module
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
    params.require(:result).permit(:name, :archived, asset_attributes: :signed_blob_id)
  end

  def create_multiple_results
    success = false
    results = []

    ActiveRecord::Base.transaction do
      params[:results_files].each do |index, file|
        asset = Asset.create!(created_by: current_user, last_modified_by: current_user, team: current_team)
        asset.file.attach(file[:signed_blob_id])
        result = Result.create!(user: current_user,
                                my_module: @my_module,
                                name: params[:results_names][index],
                                asset: asset,
                                last_modified_by: current_user)
        results << result
        # Post process file here
        asset.post_process_file(@my_module.experiment.project.team)
        log_activity(:add_result, result)
      end

      success = true
    end
    { status: success, results: results }
  end

  def log_activity(type_of, result = @result)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: result,
            team: @my_module.experiment.project.team,
            project: @my_module.experiment.project,
            message_items: {
              result: result.id,
              type_of_result: t('activities.result_type.asset')
            })
  end
end
