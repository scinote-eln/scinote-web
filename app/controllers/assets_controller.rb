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
  before_action :check_read_permission, except: %i(edit destroy duplicate create_wopi_file toggle_view_mode)
  before_action :check_manage_permission, only: %i(edit destroy duplicate rename toggle_view_mode restore_version)

  def file_preview
    editable = can_manage_asset?(@asset) && (@asset.repository_asset_value.blank? ||
                !@asset.repository_cell.repository_row.repository.is_a?(SoftLockedRepository))
    render json: { html: render_to_string(
      partial: 'shared/file_preview/content',
      locals: {
        asset: @asset,
        can_edit: editable,
        gallery: params[:gallery],
        preview: params[:preview]
      },
      formats: :html
    ) }
  end

  def toggle_view_mode
    @asset.view_mode = toggle_view_mode_params[:view_mode]
    @asset.save!(touch: false)

    render json: AssetSerializer.new(@asset, scope: { user: current_user }).as_json
  end

  def load_asset
    gallery_view_id = if @assoc.is_a?(Step)
                        @assoc.id
                      elsif @assoc.is_a?(Result)
                        @assoc.my_module.id
                      end
    render json: { html: render_to_string(partial: 'assets/asset',
                                          locals: {
                                            asset: @asset,
                                            gallery_view_id: gallery_view_id
                                          },
                                          formats: :html) }
  end

  def move_targets
    if @assoc.is_a?(Step)
      protocol = @assoc.protocol
      render json: { targets: protocol.steps.order(:position).where.not(id: @assoc.id).map { |i| [i.id, i.name] } }
    elsif @assoc.is_a?(Result)
      my_module = @assoc.my_module
      render json: { targets: my_module.results.active.where.not(id: @assoc.id).map { |i| [i.id, i.name] } }
    else
      render json: { targets: [] }
    end
  end

  def move
    case @assoc
    when Step
      target = @assoc.protocol.steps.find_by(id: params[:target_id])
    when Result
      target = @assoc.my_module.results.active.find_by(id: params[:target_id])
      return render_404 unless target
    end

    ActiveRecord::Base.transaction do
      if @assoc.is_a?(Step)
        object_to_update = @asset.step_asset
        object_to_update.update!(step: target)

        if @assoc.protocol.in_module?
          log_step_activity(
            @asset.file.metadata[:asset_type] == 'marvinjs' ? :move_chemical_structure_on_step : :task_step_file_moved,
            @assoc,
            @assoc.my_module.project,
            my_module: @assoc.my_module.id,
            file: @asset.file_name,
            user: current_user.id,
            step_position_original: @asset.step.position + 1,
            step_original: @asset.step.id,
            step_position_destination: target.position + 1,
            step_destination: target.id
          )
        else
          log_step_activity(
            @asset.file.metadata[:asset_type] == 'marvinjs' ? :move_chemical_structure_on_step_in_repository : :protocol_step_file_moved,
            @assoc,
            nil,
            protocol: @assoc.protocol.id,
            file: @asset.file_name,
            user: current_user.id,
            step_position_original: @asset.step.position + 1,
            step_original: @asset.step.id,
            step_position_destination: target.position + 1,
            step_destination: target.id
          )
        end

        render json: {}
      elsif @assoc.is_a?(Result)
        object_to_update = @asset.result_asset
        object_to_update.update!(result: target)

        type_of = {
          'marvinjs' => :move_chemical_structure_on_result,
          'gene_sequence' => :sequence_on_result_moved
        }.fetch(@asset.file.metadata[:asset_type], :result_file_moved)

        log_result_activity(
          type_of,
          @assoc,
          file: @asset.file_name,
          user: current_user.id,
          result_original: @assoc.id,
          result_destination: target.id
        )

        render json: {}
      end
    rescue ActiveRecord::RecordInvalid
      render json: object_to_update.errors, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def file_url
    return render_404 unless @asset.file.attached?

    render plain: @asset.file.blob.url
  end

  def download
    redirect_to rails_blob_path(@asset.file, disposition: 'attachment')
  end

  def show
    if @asset
      render json: @asset, serializer: AssetSerializer, user: current_user
    else
      render json: { error: 'Asset not found' }, status: :not_found
    end
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

    redirect_to @asset.file_pdf_preview.url
  end

  def create_start_edit_image_activity
    create_edit_image_activity(@asset, current_user, :start_editing)
  end

  def update_image
    @asset = Asset.find(params[:id])
    orig_file_size = @asset.file_size
    orig_file_name = @asset.file_name
    return render_403 unless can_read_team?(@asset.team)

    @asset.last_modified_by = current_user
    @asset.attach_file_version(io: params.require(:image), filename: orig_file_name)
    @asset.save!
    create_edit_image_activity(@asset, current_user, :finish_editing)
    # release previous image space
    @asset.team.release_space(orig_file_size)
    # Post process file here
    @asset.post_process_file
    @asset.step&.protocol&.update(updated_at: Time.zone.now)

    render_html = if [Result, Step].include?(@assoc.class)
                    gallery_view_id = if @assoc.is_a?(Step)
                                        @assoc.id
                                      elsif @assoc.is_a?(Result)
                                        @assoc.my_module.id
                                      end

                    render_to_string(
                      partial: 'assets/asset',
                      locals: {
                        asset: @asset,
                        gallery_view_id: gallery_view_id
                      },
                      formats: :html
                    )
                  else
                    render_to_string(
                      partial: 'assets/asset_link',
                      locals: { asset: @asset, display_image_tag: true },
                      formats: :html
                    )
                  end

    render json: { html: render_html }
  end

  # POST: create_wopi_file_path
  def create_wopi_file
    # Presence validation
    params.require(%i(element_type element_id file_type))

    # File type validation
    render_403 && return unless %w(docx xlsx pptx).include?(params[:file_type])

    # Asset validation
    asset = Asset.new(created_by: current_user, team: current_team)
    asset.attach_file_version(io: StringIO.new,
                              filename: "#{params[:file_name]}.#{params[:file_type]}",
                              content_type: wopi_content_type(params[:file_type]),
                              current_user: current_user)

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
      result = Result.find(params[:element_id].to_i)
      render_403 and return unless can_manage_result?(result)

      result_asset = ResultAsset.create!(result: result, asset: asset)
      asset.update!(view_mode: result.assets_view_mode)

      edit_url = edit_asset_url(result_asset.asset_id)
    else
      render_404 and return
    end

    # Return edit url and asset info
    render json: asset, scope: { user: current_user }
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
        log_result_activity(
          @asset.file.metadata[:asset_type] == 'gene_sequence' ? :sequence_on_result_deleted : :result_file_deleted,
          @assoc,
          file: @asset.file_name
        )
      end

      render json: { flash: I18n.t('assets.file_deleted', file_name: escape_input(@asset.file_name)) }
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def rename
    new_name = params.require(:asset).permit(:name)[:name]

    if new_name.empty?
      render json: { error: I18n.t('assets.rename_modal.min_length_error') }, status: :unprocessable_entity
      return
    elsif new_name.length > Constants::NAME_MAX_LENGTH
      render json: { error: I18n.t('assets.rename_modal.max_length_error') }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      old_name = @asset.file_name
      @asset.last_modified_by = current_user
      @asset.rename_file(new_name)
      @asset.save!

      case @asset.parent
      when Step
        message_items = { old_name:, new_name:, user: current_user.id }
        message_items[:my_module] = @assoc.protocol.my_module.id if @assoc.protocol.in_module?
        @asset.parent.touch
        log_step_activity(
          "#{@assoc.protocol.in_module? ? 'task' : 'protocol'}_step_asset_renamed",
          @assoc,
          @assoc.my_module&.project,
          message_items
        )
      when Result
        log_result_activity(
          :result_asset_renamed,
          @assoc,
          old_name:,
          new_name:,
          user: current_user.id,
          my_module: @assoc.my_module.id
        )
      end
    end

    render json: @asset, serializer: AssetSerializer, user: current_user
  end

  def duplicate
    ActiveRecord::Base.transaction do
      case @asset.parent
      when Step, Result
        new_asset = @asset.duplicate(
          new_name:
            "#{@asset.file.filename.base} (1).#{@asset.file.filename.extension}"
        )

        @asset.parent.assets << new_asset
      end

      case @asset.parent
      when Step
        message_items = { file: @asset.file_name }
        message_items[:my_module] = @assoc.protocol.my_module.id if @assoc.protocol.in_module?

        log_step_activity(
          "#{@assoc.protocol.in_module? ? 'task' : 'protocol'}_step_file_duplicated",
          @assoc,
          @assoc.my_module&.project,
          message_items
        )
      when Result
        log_result_activity(
          :result_file_duplicated,
          @assoc,
          file: @asset.file_name,
          user: current_user.id,
          my_module: @assoc.my_module.id
        )
      end

      render json: new_asset, serializer: AssetSerializer, user: current_user
    end
  end

  def checksum
    render json: { checksum: @asset.file.blob.checksum }
  end

  def versions
    blobs =
      [@asset.file.blob] +
      @asset.previous_files.map(&:blob).sort_by { |b| -1 * b.metadata['version'].to_i }[0..(VersionedAttachments.enabled? ? -1 : 1)]
    render(
      json: ActiveModel::SerializableResource.new(
        blobs,
        each_serializer: ActiveStorage::BlobSerializer
      ).as_json.merge(
        enabled: VersionedAttachments.enabled?,
        enable_url: ENV.fetch('SCINOTE_FILE_VERSIONING_ENABLE_URL', nil)
      )
    )
  end

  def restore_version
    render_403 unless VersionedAttachments.enabled?

    @asset.restore_file_version(params[:version].to_i)
    render json: @asset.file.blob
  end

  private

  def load_vars
    @asset = Asset.find_by(id: params[:id])
    return render_404 unless @asset

    current_user.permission_team = @asset.team

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

  def check_manage_permission
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

  def log_result_activity(type_of, result, message_items)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: result,
            team: result.my_module.team,
            project: result.my_module.project,
            message_items: {
              result: result.id
            }.merge(message_items))
  end
end
