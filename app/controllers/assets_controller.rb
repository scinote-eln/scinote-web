class AssetsController < ApplicationController
  include WopiUtil
  # include ActionView::Helpers
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include InputSanitizeHelper
  include FileIconsHelper

  before_action :load_vars
  before_action :check_read_permission, except: :file_present
  before_action :check_edit_permission, only: :edit

  def file_present
    respond_to do |format|
      format.json do
        if @asset.file.processing?
          render json: {}, status: 404
        else
          # Only if file is present,
          # check_read_permission
          check_read_permission

          # If check_read_permission already rendered error,
          # stop execution
          return if performed?

          # If check permission passes, return :ok
          render json: {
            'asset-id' => @asset.id,
            'image-tag-url' => @asset.url(:medium),
            'preview-url' => asset_file_preview_path(@asset),
            'filename' => truncate(@asset.file_file_name,
                                   length:
                                     Constants::FILENAME_TRUNCATION_LENGTH),
            'download-url' => download_asset_path(@asset),
            'type' => asset_data_type(@asset)
          }, status: 200
        end
      end
    end
  end

  def file_preview
    response_json = {
      'id' => @asset.id,
      'type' => (@asset.is_image? ? 'image' : 'file'),

      'filename' => truncate(@asset.file_file_name,
                             length:
                               Constants::FILENAME_TRUNCATION_LENGTH),
      'download-url' => download_asset_path(@asset, timestamp: Time.now.to_i),
      'editable'     => @asset.editable?(current_user)
    }

    if @asset.is_image?
      response_json.merge!(
        'processing'        => @asset.file.processing?,
        'large-preview-url' => @asset.url(:large),
        'processing-url'    => image_tag('medium/processing.gif')
      )
    else
      response_json.merge!(
        'processing'   => @asset.file.processing?,
        'preview-icon' => render_to_string(
          partial: 'shared/file_preview_icon.html.erb',
          locals: { asset: @asset }
        )
      )
    end

    if wopi_file?(@asset)
      can_edit =
        if @assoc.class == Step
          can_manage_protocol_in_module?(@protocol) ||
            can_manage_protocol_in_repository?(@protocol)
        elsif @assoc.class == Result
          can_manage_module?(@my_module)
        elsif @assoc.class == RepositoryCell
          can_manage_repository_rows?(@repository.team)
        end
      edit_supported, title = wopi_file_edit_button_status
      response_json['wopi-controls'] = render_to_string(
        partial: 'shared/file_wopi_controlls.html.erb',
        locals: {
          asset: @asset,
          can_edit: can_edit,
          edit_supported: edit_supported,
          title: title
        }
      )
    end
    respond_to do |format|
      format.json do
        render json: response_json
      end
    end
  end

  # Check whether the wopi file can be edited and return appropriate response
  def wopi_file_edit_button_status
    file_ext = @asset.file_file_name.split('.').last
    if Constants::WOPI_EDITABLE_FORMATS.include?(file_ext)
      edit_supported = true
      title = ''
    else
      edit_supported = false
      title = if Constants::FILE_TEXT_FORMATS.include?(file_ext)
                I18n.t('assets.wopi_supported_text_formats_title')
              elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
                I18n.t('assets.wopi_supported_table_formats_title')
              else
                I18n.t('assets.wopi_supported_presentation_formats_title')
              end
    end
    return edit_supported, title
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

  def edit
    @action_url = append_wd_params(@asset
                                   .get_action_url(current_user, 'edit', false))
    @favicon_url = @asset.favicon_url('edit')
    tkn = current_user.get_wopi_token
    @token = tkn.token
    @ttl = (tkn.ttl * 1000).to_s
    create_wopi_file_activity(current_user, true)

    render layout: false
  end

  def view
    @action_url = append_wd_params(@asset
                                   .get_action_url(current_user, 'view', false))
    @favicon_url = @asset.favicon_url('view')
    tkn = current_user.get_wopi_token
    @token = tkn.token
    @ttl = (tkn.ttl * 1000).to_s

    render layout: false
  end

  def update_image
    @asset = Asset.find(params[:id])
    return render_403 unless can_read_team?(@asset.team)
    image_file = Paperclip.io_adapters.for(params[:image])
    image_format = image_file.content_type.split('/')[1]
    image_file.original_filename = @asset.file_file_name.ext(image_format)
    @asset.file = image_file
    @asset.save!
    # Post process file here
    @asset.post_process_file(@asset.team)

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'shared/asset_link',
            locals: { asset: @asset, display_image_tag: true },
            formats: :html
          )
        }
      end
    end
  end

  private

  def load_vars
    @asset = Asset.find_by_id(params[:id])
    return render_404 unless @asset

    step_assoc = @asset.step
    result_assoc = @asset.result
    repository_cell_assoc = @asset.repository_cell
    @assoc = step_assoc unless step_assoc.nil?
    @assoc = result_assoc unless result_assoc.nil?
    @assoc = repository_cell_assoc unless repository_cell_assoc.nil?

    if @assoc.class == Step
      @protocol = @asset.step.protocol
    elsif @assoc.class == Result
      @my_module = @assoc.my_module
    elsif @assoc.class == RepositoryCell
      @repository = @assoc.repository_column.repository
    end
  end

  def check_read_permission
    if @assoc.class == Step
      render_403 && return unless can_read_protocol_in_module?(@protocol) ||
                                  can_read_protocol_in_repository?(@protocol)
    elsif @assoc.class == Result
      render_403 and return unless can_read_experiment?(@my_module.experiment)
    elsif @assoc.class == RepositoryCell
      render_403 and return unless can_read_team?(@repository.team)
    end
  end

  def check_edit_permission
    if @assoc.class == Step
      render_403 && return unless can_manage_protocol_in_module?(@protocol) ||
                                  can_manage_protocol_in_repository?(@protocol)
    elsif @assoc.class == Result
      render_403 and return unless can_manage_module?(@my_module)
    elsif @assoc.class == RepositoryCell
      render_403 and return unless can_manage_repository_rows?(@repository.team)
    end
  end

  def append_wd_params(url)
    wd_params = ''
    params.keys.select { |i| i[/^wd.*/] }.each do |wd|
      next if wd == 'wdPreviousSession' || wd == 'wdPreviousCorrelation'
      wd_params += "&#{wd}=#{params[wd]}"
    end
    url + wd_params
  end

  def asset_params
    params.permit(
      :file
    )
  end

  def asset_data_type(asset)
    return 'wopi' if wopi_file?(asset)
    return 'image' if asset.is_image?
    'file'
  end
end
