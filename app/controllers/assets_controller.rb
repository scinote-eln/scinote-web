class AssetsController < ApplicationController
  before_action :load_vars
  before_action :check_read_permission, except: :file_present

  def file_present
    respond_to do |format|
      format.json {
        if @asset.file_present
          # Only if file is present,
          # check_read_permission
          check_read_permission

          # If check_read_permission already rendered error,
          # stop execution
          if performed? then
            return
          end

          # If check permission passes, return :ok
          render json: {}, status: 200
        else
          render json: {}, status: 404
        end
      }
    end
  end

  def preview
    if @asset.is_image?
      if @asset.file.processing?
        redirect_to image_url('/images/processing.gif'), status: 307
      else
        redirect_to @asset.url(:medium), status: 307
      end
    else
      render_400
    end
  end

  def download
    if !@asset.file_present
      render_404 and return
    elsif @asset.file.is_stored_on_s3?
      redirect_to @asset.presigned_url(download: true), status: 307
    else
      send_file @asset.file.path, filename: URI.unescape(@asset.file_file_name),
        type: @asset.file_content_type
    end
  end

  private

  def load_vars
    @asset = Asset.find_by_id(params[:id])

    unless @asset
      render_404
    end

    step_assoc = @asset.step
    result_assoc = @asset.result

    @assoc = step_assoc if not step_assoc.nil?
    @assoc = result_assoc if not result_assoc.nil?

    if @assoc.class == Step
      @protocol = @asset.step.protocol
    else
      @my_module = @assoc.my_module
    end
  end

  def check_read_permission
    if @assoc.class == Step
      unless can_view_or_download_step_assets(@protocol)
        render_403 and return
      end
    elsif @assoc.class == Result
      unless can_view_or_download_result_assets(@my_module)
        render_403 and return
      end
    end
  end

  def asset_params
    params.permit(
      :file
    )
  end
end
