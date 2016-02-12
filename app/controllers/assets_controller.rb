class AssetsController < ApplicationController
  before_action :load_vars, except: [:signature]
  before_action :check_read_permission, except: [:signature]

  def signature
    respond_to do |format|
      format.json {

        if params[:asset_id]
          asset = Asset.find_by_id params[:asset_id]
          asset.file.destroy
          asset.file_empty params[:file_name], params[:file_size]
        else
          asset = Asset.new_empty params[:file_name], params[:file_size]
        end

        if not asset.valid?
          errors = Hash[asset.errors.map{|k,v| ["asset.#{k}",v]}]

          render json: {
            status: 'error',
            errors: errors
          }
        else
          asset.save!

          posts = generate_upload_posts asset

          render json: {
            asset_id: asset.id,
            posts: posts
          }
        end
      }
    end
  end

  def preview
    if @asset.is_image?
      url = @asset.file.url :medium
      redirect_to url, status: 307     
    else
      render_400
    end
  end

  def download
    if @asset.file.is_stored_on_s3?
      redirect_to @asset.presigned_url, status: 307
    else
      send_file @asset.file.path, filename: @asset.file_file_name,
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

    @my_module = @assoc.my_module
    @project = @my_module.project
  end

  def check_read_permission

    if @assoc.class == Step
      unless can_download_step_assets(@my_module)
        render_403
      end
    elsif @assoc.class == Result
      unless can_download_result_assets(@my_module)
        render_403
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
      content_length_range: 1..(1024*1024*50),
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
          content_length_range: 1..(1024*1024*50),
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
end

