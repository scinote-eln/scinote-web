class ResultAssetsController < ApplicationController
  include ResultsHelper

  before_action :load_vars, only: [:edit, :update, :download]
  before_action :load_vars_nested, only: [:new, :create]
  before_action :load_paperclip_vars

  before_action :check_create_permissions, only: [:new, :create]
  before_action :check_edit_permissions, only: [:edit, :update]
  before_action :check_archive_permissions, only: [:update]

  def new
    @asset = Asset.new
    @result = Result.new(
      user: current_user,
      my_module: @my_module,
      asset: @asset
    )

    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "new.html.erb",
            locals: {
              direct_upload: @direct_upload
            }
          })
        }, status: :ok
      }
    end
  end

  def create
    asset_attrs = result_params[:asset_attributes]

    if asset_attrs and asset_attrs[:id]
      @asset = Asset.find_by_id asset_attrs[:id]
    else
      @asset = Asset.new(result_params[:asset_attributes])
    end

    @asset.created_by = current_user
    @asset.last_modified_by = current_user
    @result = Result.new(
      user: current_user,
      my_module: @my_module,
      name: result_params[:name],
      asset: @asset
    )
    @result.last_modified_by = current_user

    respond_to do |format|
      if (@result.save and @asset.save) then
        # Post process file here
        @asset.post_process_file(@my_module.project.organization)

        # Generate activity
        Activity.create(
          type_of: :add_result,
          user: current_user,
          project: @my_module.project,
          my_module: @my_module,
          message: t(
            "activities.add_asset_result",
            user: current_user.full_name,
            result: @result.name,
          )
        )

        format.html {
          flash[:success] = t(
            "result_assets.create.success_flash",
            module: @my_module.name)
          redirect_to results_my_module_path(@my_module)
        }
        format.json {
          render json: {
            status: 'ok',
            html: render_to_string({
              partial: "my_modules/result.html.erb", locals: {result: @result}
            })
          }, status: :ok
        }
      else
        # This response is sent as 200 OK due to IE security error when
        # accessing iframe content.
        format.json {
          render json: {status: 'error', errors: @result.errors}
        }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "edit.html.erb",
            locals: {
              direct_upload: @direct_upload
            }
          })
        }, status: :ok
      }
    end
  end

  def update
    update_params = result_params
    previous_size = @result.space_taken

    @result.asset.last_modified_by = current_user
    @result.last_modified_by = current_user
    @result.assign_attributes(update_params)
    success_flash = t("result_assets.update.success_flash",
            module: @my_module.name)
    if @result.archived_changed?(from: false, to: true)
      saved = @result.archive(current_user)
      success_flash = t("result_assets.archive.success_flash",
            module: @my_module.name)
      if saved
        Activity.create(
          type_of: :archive_result,
          project: @my_module.project,
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
      # Asset (file) and/or name has been changed
      saved = @result.save

      if saved then
        @result.reload

        # Release organization's space taken due to
        # previous asset being removed
        org = @result.my_module.project.organization
        org.release_space(previous_size)
        org.save

        # Post process new file if neccesary
        if @result.asset.present?
          @result.asset.post_process_file(org)
        end

        Activity.create(
          type_of: :edit_result,
          user: current_user,
          project: @my_module.project,
          my_module: @my_module,
          message: t(
            "activities.edit_asset_result",
            user: current_user.full_name,
            result: @result.name
          )
        )
      end
    end

    respond_to do |format|
      if saved
        format.html {
          flash[:success] = success_flash
          redirect_to results_my_module_path(@my_module)
        }
        format.json {
          render json: {
            status: 'ok',
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

  private

  def load_paperclip_vars
    @direct_upload = ENV['PAPERCLIP_DIRECT_UPLOAD']
  end

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

    unless @my_module
      render_404
    end
  end

  def check_create_permissions
    unless can_create_result_asset_in_module(@my_module)
      render_403
    end
  end

  def check_edit_permissions
    unless can_edit_result_asset_in_module(@my_module)
      render_403
    end
  end

  def check_archive_permissions
    if result_params[:archived].to_s != '' and
      not can_archive_result(@result)
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
end
