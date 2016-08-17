class AssetsController < ApplicationController
  before_action :load_vars, except: [:signature]
  before_action :check_read_permission, except: [:signature, :file_present]

  # Validates asset and then generates S3 upload posts, because
  # otherwise untracked files could be uploaded to S3
  def signature
    respond_to do |format|
      format.json {

        asset = Asset.new(asset_params)
        if asset.errors.any?
          # We need to validate, although 'new' already does it, so that
          # asset's after_validation gets triggered, which modifies errors
          asset.valid?
          render json: {
            status: 'error',
            errors: asset.errors
          }, status: :bad_request
        else
          posts = generate_upload_posts asset
          render json: {
            posts: posts
          }
        end
      }
    end
  end

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
      redirect_to @asset.presigned_url(:medium), status: 307
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

  def generate_upload_posts(asset)
    posts = []
    s3_post = S3_BUCKET.presigned_post(
      key: asset.file.path[1..-1],
      success_action_status: '201',
      acl: 'private',
      storage_class: "STANDARD",
      content_length_range: 1..(FILE_SIZE_LIMIT.megabytes),
      content_type: asset.file_content_type
    )
    posts.push({
      url: s3_post.url,
      fields: s3_post.fields
    })

    if (asset.file_content_type =~ /^image\//) == 0
      asset.file.options[:styles].each do |style, option|
        s3_post = S3_BUCKET.presigned_post(
          key: asset.file.path(style)[1..-1],
          success_action_status: '201',
          acl: 'public-read',
          storage_class: "REDUCED_REDUNDANCY",
          content_length_range: 1..(FILE_SIZE_LIMIT.megabytes),
          content_type: asset.file_content_type
        )
        posts.push({
          url: s3_post.url,
          fields: s3_post.fields,
          style_option: option,
          mime_type: asset.file_content_type
        })
      end
    end

    posts
  end

  def asset_params
    params.permit(
      :file
    )
  end
end
