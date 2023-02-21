# frozen_string_literal: true

class AssetsController < ApplicationController
  include WopiUtil
  include AssetsActions
  include ActiveStorage::SetCurrent
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include ActiveStorageFileUtil
  include ApplicationHelper
  include InputSanitizeHelper
  include FileIconsHelper
  include MyModulesHelper

  helper_method :wopi_file_edit_button_status

  before_action :load_vars, except: :create_wopi_file
  before_action :check_read_permission, except: %i(edit destroy create_wopi_file toggle_view_mode)
  before_action :check_edit_permission, only: %i(edit destroy toggle_view_mode)

  def file_preview
    render json: { html: render_to_string(
      partial: 'shared/file_preview/content.html.erb',
      locals: {
        asset: @asset,
        can_edit: can_manage_asset?(@asset),
        gallery: params[:gallery],
        preview: params[:preview]
      }
    ) }
  end

  def toggle_view_mode
    @asset.view_mode = toggle_view_mode_params[:view_mode]
    if @asset.save(touch: false)
      gallery_view_id = if @assoc.is_a?(Step)
                          @assoc.id
                        elsif @assoc.is_a?(Result)
                          @assoc.my_module.id
                        end
      html = render_to_string(partial: 'assets/asset.html.erb', locals: {
                                asset: @asset,
                                gallery_view_id: gallery_view_id
                              })
      respond_to do |format|
        format.json do
          render json: { html: html }, status: :ok
        end
      end
    end
  end

  def load_asset
    gallery_view_id = if @assoc.is_a?(Step)
                        @assoc.id
                      elsif @assoc.is_a?(Result)
                        @assoc.my_module.id
                      end
    render json: { html: render_to_string(partial: 'assets/asset.html.erb',
                                          locals: {
                                            asset: @asset,
                                            gallery_view_id: gallery_view_id
                                          }) }
  end

  def file_url
    return render_404 unless @asset.file.attached?

    render plain: @asset.file.blob.service_url
  end

  def download
    redirect_to rails_blob_path(@asset.file, disposition: 'attachment')
  end

  def edit
    action = @asset.file_size.zero? && !@asset.locked? ? 'editnew' : 'edit'
    @action_url = append_wd_params(@asset.get_action_url(current_user, action, false))
    @favicon_url = @asset.favicon_url('edit')
    tkn = current_user.get_wopi_token
    @token = tkn.token
    @ttl = (tkn.ttl * 1000).to_s
    @asset.step&.protocol&.update(updated_at: Time.zone.now)

    create_wopi_file_activity(current_user, true)

    render layout: false
  end

  def view
    @action_url = append_wd_params(@asset.get_action_url(current_user, 'view', false))
    @favicon_url = @asset.favicon_url('view')
    tkn = current_user.get_wopi_token
    @token = tkn.token
    @ttl = (tkn.ttl * 1000).to_s

    render layout: false
  end

  def pdf_preview
    return render plain: '', status: :not_acceptable unless previewable_document?(@asset.blob)
    return render plain: '', status: :accepted unless @asset.pdf_preview_ready?

    redirect_to @asset.file_pdf_preview.service_url
  end

  def create_start_edit_image_activity
    create_edit_image_activity(@asset, current_user, :start_editing)
  end

  def update_image
    @asset = Asset.find(params[:id])
    orig_file_size = @asset.file_size
    orig_file_name = @asset.file_name
    return render_403 unless can_read_team?(@asset.team)

    @asset.file.attach(io: params.require(:image), filename: orig_file_name)
    @asset.save!
    create_edit_image_activity(@asset, current_user, :finish_editing)
    # release previous image space
    @asset.team.release_space(orig_file_size)
    # Post process file here
    @asset.post_process_file(@asset.team)
    @asset.step&.protocol&.update(updated_at: Time.zone.now)

    render_html = if [Result, Step].include?(@assoc.class)
                    gallery_view_id = if @assoc.is_a?(Step)
                                        @assoc.id
                                      elsif @assoc.is_a?(Result)
                                        @assoc.my_module.id
                                      end

                    render_to_string(
                      partial: 'assets/asset.html.erb',
                      locals: {
                        asset: @asset,
                        gallery_view_id: gallery_view_id
                      },
                      formats: :html
                    )
                  else
                    render_to_string(
                      partial: 'assets/asset_link.html.erb',
                      locals: { asset: @asset, display_image_tag: true },
                      formats: :html
                    )
                  end

    respond_to do |format|
      format.json do
        render json: { html: render_html }
      end
    end
  end

  # POST: create_wopi_file_path
  def create_wopi_file
    # Presence validation
    params.require(%i(element_type element_id file_type))

    # File type validation
    render_403 && return unless %w(docx xlsx pptx).include?(params[:file_type])

    # Asset validation
    asset = Asset.new(created_by: current_user, team: current_team)
    asset.file.attach(io: StringIO.new,
                      filename: "#{params[:file_name]}.#{params[:file_type]}",
                      content_type: wopi_content_type(params[:file_type]))

    unless asset.valid?(:wopi_file_creation)
      render json: {
        message: asset.errors
      }, status: :bad_request and return
    end

    # Create file depending on the type
    if params[:element_type] == 'Step'
      step = Step.find(params[:element_id].to_i)
      render_403 && return unless can_manage_step?(step)

      step_asset = StepAsset.create!(step: step, asset: asset)
      asset.update!(view_mode: step.assets_view_mode)
      step.protocol&.update(updated_at: Time.zone.now)

      edit_url = edit_asset_url(step_asset.asset_id)
    elsif params[:element_type] == 'Result'
      my_module = MyModule.find(params[:element_id].to_i)
      render_403 and return unless can_manage_my_module?(my_module)

      # First create result and then the asset
      result = Result.create(name: asset.file_name,
                             my_module: my_module,
                             user: current_user)
      result_asset = ResultAsset.create!(result: result, asset: asset)

      edit_url = edit_asset_url(result_asset.asset_id)
    else
      render_404 and return
    end

    # Prepare file preview in advance
    asset.medium_preview.processed && asset.large_preview.processed
    # Return edit url and asset info
    render json: {
      attributes: AssetSerializer.new(asset, scope: { user: current_user }).as_json,
      success: true,
      edit_url: edit_url
    }, status: :ok
  end

  def destroy
    if @asset.destroy
      case @assoc
      when Step
        if @assoc.protocol.in_module?
          log_step_activity(
            :task_step_file_deleted,
            @assoc,
            @assoc.my_module.project,
            my_module: @assoc.my_module.id,
            file: @asset.file_name
          )
        else
          log_step_activity(
            :protocol_step_file_deleted,
            @assoc,
            nil,
            protocol: @assoc.protocol.id,
            file: @asset.file_name
          )
        end
      when Result
        log_result_activity(:edit_result, @assoc)
      end

      render json: { flash: I18n.t('assets.file_deleted', file_name: @asset.file_name) }
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  private

  def load_vars
    @asset = Asset.find_by(id: params[:id])
    return render_404 unless @asset

    @assoc ||= @asset.step
    @assoc ||= @asset.result
    @assoc ||= @asset.repository_cell

    if @assoc.class == Step
      @protocol = @asset.step.protocol
    elsif @assoc.class == Result
      @my_module = @assoc.my_module
    elsif @assoc.class == RepositoryCell
      @repository = @assoc.repository_column.repository
    end
  end

  def check_read_permission
    render_403 and return unless can_read_asset?(@asset)
  end

  def check_edit_permission
    render_403 and return unless can_manage_asset?(@asset)
  end

  def append_wd_params(url)
    exclude_params = %w(wdPreviousSession wdPreviousCorrelation)
    wd_params = params.as_json.select { |key, _value| key[/^wd.*/] && !(exclude_params.include? key) }.to_query
    url + '&' + wd_params
  end

  def asset_params
    params.permit(:file)
  end

  def toggle_view_mode_params
    params.require(:asset).permit(:view_mode)
  end

  def asset_data_type(asset)
    return 'wopi' if wopi_file?(asset)
    return 'image' if asset.image?

    'file'
  end

  def log_step_activity(type_of, step, project = nil, message_items = {})
    default_items = { step: step.id,
                      step_position: { id: step.id, value_for: 'position_plus_one' } }
    message_items = default_items.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: step.protocol,
            team: step.protocol.team,
            project: project,
            message_items: message_items)
  end

  def log_result_activity(type_of, result)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: result,
            team: result.my_module.team,
            project: result.my_module.project,
            message_items: {
              result: result.id,
              type_of_result: t('activities.result_type.text')
            })
  end
end
