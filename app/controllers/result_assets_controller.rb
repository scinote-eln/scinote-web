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
    update_params = result_params
    previous_size = @result.space_taken
    previous_asset = @result.asset

    if update_params.key? :asset_attributes
      asset = Asset.find_by_id(update_params[:asset_attributes][:id])
      asset.created_by = current_user
      asset.last_modified_by = current_user
      asset.team = current_team
      @result.asset = asset
    end

    @result.last_modified_by = current_user
    @result.assign_attributes(update_params)
    success_flash = t('result_assets.update.success_flash',
                      module: @my_module.name)

    if @result.archived_changed?(from: false, to: true)
      if previous_asset.locked?
        respond_to do |format|
          format.html do
            flash[:error] = t('result_assets.archive.error_flash')
            redirect_to results_my_module_path(@my_module)
            return
          end
        end
      end

      saved = @result.archive(current_user)
      success_flash = t('result_assets.archive.success_flash',
                        module: @my_module.name)
      if saved
        Activity.create(
          type_of: :archive_result,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          user: current_user,
          message: t(
            'activities.archive_asset_result',
            user: current_user.full_name,
            result: @result.name
          )
        )
      end
    elsif @result.archived_changed?(from: true, to: false)
      render_403
    else
      if previous_asset.locked?
        @result.errors.add(:asset_attributes,
                           t('result_assets.edit.locked_file_error'))
        respond_to do |format|
          format.json do
            render json: {
              status: 'error',
              errors: @result.errors
            }, status: :bad_request
            return
          end
        end
      end
      # Asset (file) and/or name has been changed
      saved = @result.save

      if saved
        # Release team's space taken due to
        # previous asset being removed
        team = @result.my_module.experiment.project.team
        team.release_space(previous_size)
        team.save

        # Post process new file if neccesary
        @result.asset.post_process_file(team) if @result.asset.present?

        Activity.create(
          type_of: :edit_result,
          user: current_user,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          message: t('activities.edit_asset_result',
                     user: current_user.full_name,
                     result: @result.name)
        )
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
    params.require(:result).permit(
      :name, :archived,
      asset_attributes: [
        :id,
        :file
      ]
    )
  end

  def create_multiple_results
    success = true
    results = []
    params[:results_files].values.each_with_index do |file, index|
      asset = Asset.new(file: file,
                        created_by: current_user,
                        last_modified_by: current_user,
                        team: current_team)
      result = Result.new(user: current_user,
                          my_module: @my_module,
                          name: params[:results_names][index.to_s],
                          asset: asset,
                          last_modified_by: current_user)
      if result.save && asset.save
        results << result
        # Post process file here
        asset.post_process_file(@my_module.experiment.project.team)

        # Generate activity
        Activity.create(
          type_of: :add_result,
          user: current_user,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          message: t('activities.add_asset_result',
                     user: current_user.full_name,
                     result: result.name)
        )
      else
        success = false
      end
    end
    { status: success, results: results }
  end
end
