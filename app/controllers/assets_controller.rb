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
  before_action :check_manage_permission, only: %i(edit destroy duplicate rename toggle_view_mode)
  before_action :check_restore_permission, only: :restore_version

  def file_preview
    render json: { html: render_to_string(
      partial: 'shared/file_preview/content',
      locals: {
        asset: @asset,
        can_edit: can_manage_asset?(@asset),
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
    render json: @asset, serializer: AssetSerializer, user: current_user
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
    return render_403 unless %w(docx xlsx pptx).include?(params[:file_type])

    if params[:element_type] == 'Step'
      @assoc = Step.find(params[:element_id])
      return render_403 unless can_manage_step?(@assoc)
    elsif params[:element_type] == 'Result'
      @assoc = Result.find(params[:element_id])
      return render_403 unless can_manage_result?(@assoc)
    else
      return render_403
    end

    filename = "#{params[:file_name]}.#{params[:file_type]}"

    # Asset validation
    @asset = @assoc.assets.new(created_by: current_user, team: current_team, view_mode: @assoc.assets_view_mode)
    return render json: { message: @asset.errors }, status: :bad_request unless @asset.wopi_filename_valid?(filename)

    @asset.transaction do
      # Using special version number 0 for new blank wopi files, will be used later by put_wopi_contents method
      @asset.version = 0
      @asset.save!
      # The blob will be replaced later by wopi client thus creating an empty one
      @asset.file.attach(io: StringIO.new, filename: filename, content_type: wopi_content_type(params[:file_type]))
    end

    # Return edit url and asset info
    render json: @asset, scope: { user: current_user }
  end

  def destroy
    if @asset.destroy
      message_items = if  (@asset.file.metadata[:asset_type] == 'gene_sequence' && !@assoc.is_a?(Result)) || @asset.file.metadata[:asset_type] == 'marvinjs'
                        { asset_name: @asset.file_name }
                      else
                        { file: @asset.file_name }
                      end

      activity_type = type_of_delete_activity

      case @assoc
      when Step
        module_or_protocol = @assoc.protocol.in_module? ? { my_module: @assoc.my_module.id } : { protocol: @assoc.protocol.id }
        message_items.merge!(module_or_protocol)

        log_step_activity(
          activity_type,
          @assoc,
          @assoc.protocol.in_module? ? @assoc.my_module.project : nil,
          message_items
        )
      when Result
        log_result_activity(activity_type, @assoc, message_items)
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
            "#{@asset.file.filename.base} (1).#{@asset.file.filename.extension}",
          created_by: current_user
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
        each_serializer: ActiveStorage::BlobSerializer,
        user: current_user
      ).as_json.merge(
        enabled: VersionedAttachments.enabled?,
        enable_url: ENV.fetch('SCINOTE_FILE_VERSIONING_ENABLE_URL', nil),
        disabled_disclaimer: VersionedAttachments.disabled_disclaimer
      )
    )
  end

  def restore_version
    render_403 unless VersionedAttachments.enabled?

    @asset.last_modified_by = current_user

    @asset.restore_file_version(params[:version].to_i)
    @asset.restore_preview_image_version(params[:version].to_i) if @asset.preview_image.attached?

    message_items = {
      version: params[:version].to_i,
      file: @asset.file_name
    }

    case @asset.parent
    when Step
      if @asset.parent.protocol.in_module?
        message_items.merge!({ my_module: @assoc.protocol.my_module.id, step: @asset.parent.id })
        log_restore_activity(:task_step_restore_asset_version, @assoc.protocol,
                             @assoc.protocol.team, @assoc.my_module&.project, message_items)
      else
        message_items.merge!({ protocol: @assoc.protocol.id, step: @asset.parent.id })
        log_restore_activity(:protocol_step_restore_asset_version, @assoc.protocol,
                             @assoc.protocol.team, nil, message_items)
      end
    when Result
      message_items.merge!({ result: @assoc.id, my_module: @assoc.my_module.id })
      log_restore_activity(:task_result_restore_asset_version, @assoc,
                           @assoc.my_module.team, @assoc.my_module.project, message_items)
    when RepositoryCell
      message_items.merge!({ repository_column: @assoc.repository_column.id, repository: @repository.id })
      log_restore_activity(:repository_column_restore_asset_version, @repository,
                           @repository.team, nil, message_items)
    end

    @asset.save!

    render json: @asset.file.blob
  end

  private

  def load_vars
    @asset = Asset.find_by(id: params[:id])
    return render_404 unless @asset

    # don't overwrite permission team if asset is in a repositoy, since then sharing rules may apply and depend on user's current team
    current_user.permission_team = @asset.team unless @asset.repository_cell

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

  def check_restore_permission
    render_403 and return unless can_restore_asset?(@asset)
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

  def log_restore_activity(type_of, subject, team, project = nil, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: subject,
            team: team,
            project: project,
            message_items: message_items)
  end

  def type_of_delete_activity
    case @assoc
    when Step
      case @asset.file.metadata[:asset_type]
      when 'gene_sequence'
        @assoc.protocol.in_module? ? :task_sequence_asset_deleted : :protocol_sequence_asset_deleted
      when 'marvinjs'
        @assoc.protocol.in_module? ? :delete_chemical_structure_on_step : :delete_chemical_structure_on_step_in_repository
      else
        @assoc.protocol.in_module? ? :task_step_file_deleted : :protocol_step_file_deleted
      end
    when Result
      case @asset.file.metadata[:asset_type]
      when 'gene_sequence'
        :sequence_on_result_deleted
      when 'marvinjs'
        :delete_chemical_structure_on_result
      else
        :result_file_deleted
      end
    end
  end
end
