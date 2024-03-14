class ProtocolsController < ApplicationController
  include RenamingUtil
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include ProtocolsIoHelper
  include TeamsHelper
  include ProtocolsExporterV2
  include UserRolesHelper

  before_action :check_create_permissions, only: %i(
    create
  )
  before_action :check_clone_permissions, only: [:clone]
  before_action :check_view_permissions, only: %i(
    show
    print
    versions_modal
    protocol_status_bar
    linked_children
    linked_children_datatable
    versions_list
    permissions
  )
  before_action :switch_team_with_param, only: %i(index protocolsio_index)
  before_action :check_view_all_permissions, only: %i(
    index
    protocolsio_index
    datatable
  )
  before_action :check_manage_permissions, only: %i(
    update_keywords
    update_description
    update_version_comment
    update_name
    update_authors
    unlink
    unlink_modal
    delete_steps
  )

  before_action :check_manage_with_read_protocol_permissions, only: %i(
    revert
    revert_modal
    update_from_parent
    update_from_parent_modal
  )
  before_action :check_restore_all_in_repository_permissions, only: :restore
  before_action :check_archive_all_in_repository_permissions, only: :archive
  before_action :check_load_from_repository_views_permissions, only: %i(
    load_from_repository_modal
    load_from_repository_datatable
  )
  before_action :check_load_from_repository_permissions, only: [
    :load_from_repository
  ]
  before_action :check_copy_to_repository_permissions, only: %i(
    copy_to_repository
  )

  before_action :check_publish_permission, only: %i(publish version_comment update_version_comment)
  before_action :check_import_permissions, only: :import
  before_action :check_export_permissions, only: :export
  before_action :check_delete_draft_permissions, only: :destroy_draft
  before_action :check_save_as_draft_permissions, only: :save_as_draft

  before_action :check_protocolsio_import_permissions,
                only: %i(protocolsio_import_create protocolsio_import_save)

  before_action :set_importer, only: :import
  before_action :set_inline_name_editing, only: :show
  before_action :set_breadcrumbs_items, only: %i(index show)

  layout 'fluid'

  def index
    respond_to do |format|
      format.json do
        protocols = Lists::ProtocolsService.new(Protocol.viewable_by_user(current_user, @current_team), params).call
        render json: protocols,
               each_serializer: Lists::ProtocolSerializer,
               user: current_user,
               meta: pagination_dict(protocols)
      end
      format.html do
        render 'index'
      end
    end
  end

  def versions_modal
    return render_403 unless @protocol.in_repository_published_original? || @protocol.initial_draft?

    @published_versions = @protocol.published_versions_with_original.order(version_number: :desc)

    if @protocol.draft.present? || @protocol.initial_draft?
      draft = @protocol.initial_draft? ? @protocol : @protocol.draft
      draft_hash = ProtocolDraftSerializer.new(draft, scope: current_user).as_json
    end

    render json: {
      draft: draft_hash,
      versions: @published_versions.map do |version|
        ProtocolVersionSerializer.new(version, scope: current_user).as_json
      end
    }
  end

  def print
    render layout: 'protocols/print'
  end

  def linked_children
    if params[:version].present?
      records = @protocol.published_versions_with_original
                         .find_by!(version_number: params[:version])
                         .linked_children
    else
      records = Protocol.where(protocol_type: Protocol.protocol_types[:linked])
      records = records.where(parent_id: @protocol.published_versions)
                       .or(records.where(parent_id: @protocol.id))
    end
    records = records.preload(my_module: { experiment: { project: :project_folder } })
                     .distinct.order(updated_at: :desc).page(params[:page]).per(10)

    render json: {
      data: records.map { |record|
        project_folder = record.my_module.experiment.project.project_folder

        {
          my_module_name: record.my_module.name,
          experiment_name: record.my_module.experiment.name,
          project_name: record.my_module.experiment.project.name,
          my_module_url: protocols_my_module_path(record.my_module),
          experiment_url: my_modules_path(experiment_id: record.my_module.experiment.id),
          project_url: experiments_path(project_id: record.my_module.experiment.project.id),
          project_folder_name: project_folder.present? ? project_folder.name : nil,
          project_folder_url: project_folder.present? ? project_folder_projects_url(project_folder) : nil
        }
      },
      next_page: records.next_page,
      total_pages: records.total_pages
    }
  end

  def versions_list
    render json: { versions: (@protocol.parent || @protocol).published_versions_with_original
                                                            .order(version_number: :desc)
                                                            .map(&:version_number) }
  end

  def linked_children_datatable
    render json: ::ProtocolLinkedChildrenDatatable.new(
      view_context,
      @protocol,
      current_user,
      self
    )
  end

  def publish
    Protocol.transaction do
      @protocol.update!(
        published_by: current_user,
        published_on: DateTime.now,
        version_comment: params[:version_comment] || @protocol.version_comment,
        protocol_type: (@protocol.parent_id.nil? ? :in_repository_published_original : :in_repository_published_version)
      )
      log_activity(:protocol_template_published,
                   nil,
                   protocol: @protocol.id,
                   version_number: @protocol.version_number)
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = @protocol.errors&.map(&:message)&.join(',')
      Rails.logger.error e.message
      raise ActiveRecord::Rollback
    rescue StandardError => e
      flash[:error] = I18n.t('errors.general')
      Rails.logger.error e.message
      raise ActiveRecord::Rollback
    end

    if params[:view] == 'show'
      redirect_to protocol_path(@protocol)
    else
      redirect_to protocols_path
    end
  end

  def destroy_draft
    Protocol.transaction do
      parent = @protocol.parent
      @protocol.destroy!
      @protocol = parent
      log_activity(:protocol_template_draft_deleted,
                   nil,
                   protocol: @protocol.id)

      if params[:version_modal]
        render json: { message: I18n.t('protocols.delete_draft_modal.success') }
      else
        flash[:success] = I18n.t('protocols.delete_draft_modal.success')
        redirect_to protocols_path
      end
    rescue ActiveRecord::RecordNotDestroyed => e
      Rails.logger.error e.message
      render json: { message: e.message }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    rescue StandardError => e
      render json: { message: I18n.t('errors.general') }, status: :unprocessable_entity
      Rails.logger.error e.message
      raise ActiveRecord::Rollback
    end
  end

  def archive
    move_protocols('archive')
  end

  def restore
    move_protocols('restore')
  end

  def edit
    render :show
  end

  def show
    respond_to do |format|
      format.json { render json: @protocol, serializer: ProtocolSerializer, user: current_user }
      format.html
    end
  end

  def update_keywords
    if @protocol.update_keywords(params[:keywords], current_user)
      log_activity(:edit_keywords_in_protocol_repository, nil, protocol: @protocol.id)
      render json: @protocol, serializer: ProtocolSerializer, user: current_user
    else
      render json: I18n.t('errors.general'), status: :unprocessable_entity
    end
  end

  def update_authors
    if @protocol.update(authors: params.require(:protocol)[:authors], last_modified_by: current_user)
      log_activity(:edit_authors_in_protocol_repository, nil, protocol: @protocol.id)
      render json: @protocol, serializer: ProtocolSerializer, user: current_user
    else
      render json: @protocol.errors, status: :unprocessable_entity
    end
  end

  def update_name
    if @protocol.update(name: params.require(:protocol)[:name], last_modified_by: current_user)
      log_activity(:edit_protocol_name_in_repository, nil, protocol: @protocol.id)
      render json: {}, status: :ok
    else
      render json: @protocol.errors, status: :unprocessable_entity
    end
  end

  def update_description
    old_description = @protocol.description
    if @protocol.update(description: params.require(:protocol)[:description], last_modified_by: current_user)
      log_activity(:edit_description_in_protocol_repository, nil, protocol: @protocol.id)
      TinyMceAsset.update_images(@protocol, params[:tiny_mce_images], current_user)
      protocol_annotation_notification(old_description)
      render json: @protocol, serializer: ProtocolSerializer, user: current_user
    else
      render json: @protocol.errors, status: :unprocessable_entity
    end
  end

  def create
    @protocol = Protocol.new(create_params)
    ts = Time.now
    @protocol.team = current_team
    @protocol.protocol_type = :in_repository_draft
    @protocol.added_by = current_user
    @protocol.record_timestamps = false
    @protocol.created_at = ts
    @protocol.updated_at = ts
    @protocol.last_modified_by = current_user

    if @protocol.save
      log_activity(:create_protocol_in_repository, nil, protocol: @protocol.id)
      redirect_to protocol_path(@protocol)
    else
      render json: { error: @protocol.errors.messages.map { |_k, v| v }.join(', ') }, status: :unprocessable_entity
    end
  end

  def delete_steps
    @protocol.with_lock do
      team = @protocol.team
      previous_size = 0
      @protocol.steps.each do |step|
        previous_size += step.space_taken

        if @protocol.in_module?
          log_activity(:destroy_step, @protocol.my_module.experiment.project,
                       my_module: @protocol.my_module.id,
                       step: step.id,
                       step_position: { id: step.id, value_for: 'position_plus_one' })
        else
          log_activity(:delete_step_in_protocol_repository, nil, step: step.id,
            step_position: { id: step.id, value_for: 'position_plus_one' })
        end

        # skip adjusting positions after destroy as this is a bulk delete
        step.skip_position_adjust = true
        step.destroy!
      end

      team.release_space(previous_size)
      team.save!
      render json: { status: 'ok' }
    rescue ActiveRecord::RecordNotDestroyed
      render json: { status: 'error' }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def clone
    cloned = nil
    Protocol.transaction do
      cloned = @original.deep_clone_repository(current_user)
    rescue StandardError
      raise ActiveRecord::Rollback
    end

    if cloned.present?
      render json: { message: t('protocols.index.clone.success_flash', original: @original.name, new: cloned.name) }
    else
      render json: { message: t('protocols.index.clone.error_flash', original: @original.name) },
             status: :bad_request
    end
  end

  def copy_to_repository
    respond_to do |format|
      transaction_error = false
      Protocol.transaction do
        @new_protocol = @protocol.copy_to_repository(Protocol.new(create_params), current_user)
        log_activity(:task_protocol_save_to_template, @my_module.experiment.project, protocol: @new_protocol.id)
      rescue StandardError => e
        transaction_error = true
        Rails.logger.error(e.message)
        Rails.logger.error(e.backtrace.join("\n"))
        raise ActiveRecord::Rollback
      end

      format.json do
        if transaction_error
          # Bad request error
          render json: {
            message: t('my_modules.protocols.copy_to_repository_modal.error_400')
          },
          status: :bad_request
        elsif @new_protocol.invalid?
          render json: { error: @new_protocol.errors.messages.map { |_, value| value }.join(' ') }, status: :unprocessable_entity
        else
          # Everything good, render 200
          render json: { message: t('my_modules.protocols.copy_to_repository_modal.success_message') }
        end
      end
      format.html
    end
  end

  def save_as_draft
    Protocol.transaction do
      draft = @protocol.save_as_draft(current_user)

      if draft.invalid?
        render json: { error: draft.errors.messages.map { |_, value| value }.join(' ') }, status: :unprocessable_entity
      else
        log_activity(:protocol_template_draft_created, nil, protocol: @protocol.id)
        render json: { url: protocol_path(draft) }
      end
    rescue StandardError => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: I18n.t('errors.general') }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def unlink
    transaction_error = false
    Protocol.transaction do
      @protocol.unlink
    rescue StandardError
      transaction_error = true
      raise ActiveRecord::Rollback
    end

    if transaction_error
      # Bad request error
      render json: {
        message: t('my_modules.protocols.unlink_error')
      }, status: :bad_request
    else
      # Everything good, display flash & render 200
      flash[:success] = t(
        'my_modules.protocols.unlink_flash'
      )
      flash.keep(:success)
      render json: {}, status: :ok
    end
  end

  def revert
    if @protocol.can_destroy?
      transaction_error = false
      Protocol.transaction do
        # Revert is basically update from parent
        @protocol.update_from_parent(current_user, @protocol.parent)
      rescue StandardError
        transaction_error = true
        raise ActiveRecord::Rollback
      end

      if transaction_error
        # Bad request error
        render json: {
          message: t('my_modules.protocols.revert_error')
        },
        status: :bad_request
      else
        # Everything good, display flash & render 200
        log_activity(:update_protocol_in_task_from_repository,
                     @protocol.my_module.experiment.project,
                     my_module: @protocol.my_module.id,
                     protocol_repository: @protocol.parent.id)
        flash[:success] = t(
          'my_modules.protocols.revert_flash'
        )
        flash.keep(:success)
        render json: {}, status: :ok
      end
    else
      render json: {
        message: t('my_modules.protocols.revert_error_locked')
      }, status: :bad_request
    end
  end

  def update_from_parent
    protocol_can_destroy = @protocol.can_destroy?
    if protocol_can_destroy
      transaction_error = false
      Protocol.transaction do
        # Find original published protocol template
        source_parent = if @protocol.parent.in_repository_published_original?
                          @protocol.parent
                        else
                          @protocol.parent.parent
                        end
        @protocol.update_from_parent(current_user, source_parent.latest_published_version_or_self)
      rescue StandardError
        transaction_error = true
        raise ActiveRecord::Rollback
      end
    end

    if !protocol_can_destroy
      render json: { message: t('my_modules.protocols.update_from_parent_error_locked') }, status: :bad_request
    elsif transaction_error
      render json: { message: t('my_modules.protocols.update_from_parent_error') }, status: :bad_request
    else
      log_activity(:update_protocol_in_task_from_repository,
                   @protocol.my_module.experiment.project,
                   my_module: @protocol.my_module.id,
                   protocol_repository: @protocol.parent.id)

      flash[:success] = t('my_modules.protocols.update_from_parent_flash')
      flash.keep(:success)
      render json: {}, status: :ok
    end
  end

  def load_from_repository
    if @protocol.can_destroy?
      transaction_error = false
      Protocol.transaction do
        @protocol.load_from_repository(@source, current_user)
      rescue StandardError => e
        Rails.logger.error(e.message)
        Rails.logger.error(e.backtrace.join("\n"))
        transaction_error = true
        raise ActiveRecord::Rollback
      end

      if transaction_error
        # Bad request error
        render json: { message: t('my_modules.protocols.load_from_repository_error') }, status: :bad_request
      else
        # Everything good, record activity, display flash & render 200
        log_activity(:load_protocol_to_task_from_repository,
                     @protocol.my_module.experiment.project,
                     my_module: @protocol.my_module.id,
                     protocol_repository: @protocol.parent.id)
        flash[:success] = t('my_modules.protocols.load_from_repository_flash')
        flash.keep(:success)
        render json: {}
      end
    else
      render json: {
        message: t('my_modules.protocols.load_from_repository_error_locked')
      }, status: :bad_request
    end
  end

  def protocolsio_index
    render json: {
      html: render_to_string({ partial: 'protocols/index/protocolsio_modal_body', formats: :html })
    }
  end

  def import
    protocol = nil
    transaction_error = false
    Protocol.transaction do
      protocol = @importer.import_new_protocol(@protocol_json)
    rescue StandardError => e
      Rails.logger.error e.backtrace.join("\n")
      transaction_error = true
      raise ActiveRecord::Rollback
    end

    if transaction_error
      render json: { status: :bad_request }, status: :bad_request
    else
      Activities::CreateActivityService
        .call(activity_type: :import_protocol_in_repository,
              owner: current_user,
              subject: protocol,
              team: protocol.team,
              message_items: {
                protocol: protocol.id
              })

      render json: { status: :ok }, status: :ok
    end
  end

  def protocolsio_import_create
    @protocolsio_too_big = false
    @protocolsio_invalid_file = false
    @protocolsio_no_file = false
    if params[:json_file].nil?
      @protocolsio_no_file = true
      respond_to do |format|
        format.js {}
      end
      return 0 # return 0 stops the rest of the controller code from executing
    end
    extension = File.extname(params[:json_file].path)
    file_size = File.size(params[:json_file].path)
    if extension != '.txt' && extension != '.json'
      @protocolsio_invalid_file = true

      respond_to do |format|
        format.js {}
      end
      return 0 # return 0 stops the rest of the controller code from executing
    end
    if file_size > Rails.configuration.x.file_max_size_mb.megabytes
      @protocolsio_too_big = true
      respond_to do |format|
        format.js {}
        # if file is too big, default to the js.erb file,
        # named the same as this controller
        # where a javascript alert is called
      end
      return 0 # return 0 stops the rest of the controller code from executing
    end
    json_file_contents = File.read(params[:json_file].path)
    json_file_contents.gsub! '\"', "'"
    # escaped double quotes too stressfull, html works with single quotes too
    # json double quotes dont get escaped since they dont match \"
    unless valid_protocol_json(json_file_contents)
      @protocolsio_invalid_file = true
      respond_to do |format|
        format.js {}
      end
      return 0 # return 0 stops the rest of the controller code from executing
    end
    @json_object = JSON.parse(json_file_contents)
    unless step_hash_null?(@json_object['steps'])
      @json_object['steps'] = protocols_io_guid_reorder_step_json(
        @json_object['steps']
      )
    end
    @protocol = Protocol.new
    respond_to do |format|
      format.js {} # go to the js.erb file named the same as this controller,
      # where a preview modal is rendered,
      # and some modals get closed and opened
    end
  rescue StandardError => e
    Rails.logger.error(e.backtrace.join("\n"))
    @protocolsio_general_error = true
    respond_to do |format|
      format.js {}
    end
  end

  def protocolsio_import_save
    @json_object = JSON.parse(params['json_object'])
    @db_json = {}
    @toolong = false
    @db_json['name'] = pio_eval_title_len(
      escape_input(not_null(params['protocol']['name']))
    )
    # since scinote only has description field, and protocols.io has many others
    # ,here i am putting everything important from protocols.io into description
    @db_json['authors'] = pio_eval_title_len(
      escape_input(not_null(params['protocol']['authors']))
    )
    @db_json['created_at'] = pio_eval_title_len(
      escape_input(not_null(params['protocol']['created_at']))
    )
    @db_json['updated_at'] = pio_eval_title_len(
      escape_input(not_null(params['protocol']['last_modified']))
    )
    @db_json['steps'] = {}

    unless step_hash_null?(@json_object['steps'])
      @db_json['steps'] = protocols_io_fill_step(
        @json_object, @db_json['steps']
      )
    end
    protocol = nil
    respond_to do |format|
      transaction_error = false
      @protocolsio_general_error = false
      Protocol.transaction do
        begin
          protocol = @importer.import_new_protocol(@db_json)
        rescue StandardError
          transaction_error = true
          raise ActiveRecord::Rollback
        end
      end
      p_name =
        if @db_json['name'].present?
          escape_input(@db_json['name'])
        else
          t('protocols.index.no_protocol_name')
        end
      if transaction_error
        @protocolsio_general_error = true
        # General something went wrong, upload to db failed error
        #  format.json {
        #    render json: { name: p_name, status: :bad_request },
        # status: :bad_request
        #  }
      else
        @protocolsio_general_error = false
        format.json do
          render json:
         { name: @db_json['name'], new_name: @db_json['name'], status: :ok },
          status: :ok
        end
      end
      format.js {}
    end
  end

  def export
    # Make a zip output stream and send it to the client
    # rubocop:disable Metrics/BlockLength
    z_output_stream = Zip::OutputStream.write_buffer do |ostream|
      ostream.put_next_entry('scinote.xml')
      ostream.print(generate_envelope_xml(@protocols))
      ostream.put_next_entry('scinote.xsd')
      ostream.print(generate_envelope_xsd)
      ostream.put_next_entry('eln.xsd')
      ostream.print(generate_eln_xsd)

      # Create folder and xml file for each protocol and populate it
      @protocols.each do |protocol|
        protocol = protocol.latest_published_version_or_self
        protocol_dir = get_guid(protocol.id).to_s
        ostream.put_next_entry("#{protocol_dir}/eln.xml")
        ostream.print(generate_protocol_xml(protocol))
        ostream = protocol.tiny_mce_assets.save_to_eln(ostream, protocol_dir)
        # Add assets to protocol folder
        next if protocol.steps.count <= 0

        protocol.steps.order(:id).each do |step|
          step_guid = get_guid(step.id)
          step_dir = "#{protocol_dir}/#{step_guid}"
          if step.assets.exists?
            step.assets.order(:id).each do |asset|
              next unless asset.file.attached?

              asset_guid = get_guid(asset.id)
              asset_file_name = asset_guid.to_s + File.extname(asset.file_name).to_s
              ostream.put_next_entry("#{step_dir}/#{asset_file_name}")
              ostream.print(asset.file.download)

              next unless asset.preview_image.attached?

              asset_preview_image_name = asset_guid.to_s + File.extname(asset.preview_image_file_name).to_s
              ostream.put_next_entry("#{step_dir}/previews/#{asset_preview_image_name}")
              ostream.print(asset.preview_image.download)
            end
          end
          ostream = step.tiny_mce_assets.save_to_eln(ostream, step_dir)

          step.step_texts.each do |step_text|
            ostream = step_text.tiny_mce_assets.save_to_eln(ostream, step_dir)
          end
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
    z_output_stream.rewind

    file_name = export_protocol_file_name(@protocols)

    @protocols.each do |protocol|
      if params[:my_module_id]
        my_module = MyModule.find(params[:my_module_id])
        Activities::CreateActivityService
          .call(activity_type: :export_protocol_from_task,
                owner: current_user,
                project: my_module.project,
                subject: my_module,
                team: my_module.team,
                message_items: {
                  my_module: params[:my_module_id].to_i
                })
      else
        Activities::CreateActivityService
          .call(activity_type: :export_protocol_in_repository,
                owner: current_user,
                subject: protocol,
                team: protocol.team,
                message_items: {
                  protocol: protocol.id
                })
      end
    end

    send_data(z_output_stream.read, filename: file_name)
  end

  def unlink_modal
    render json: {
      title: t('my_modules.protocols.confirm_link_update_modal.unlink_title'),
      message: t('my_modules.protocols.confirm_link_update_modal.unlink_message'),
      btn_text: t('my_modules.protocols.confirm_link_update_modal.unlink_btn_text'),
      url: unlink_protocol_path(@protocol)
    }
  end

  def revert_modal
    render json: {
      title: t('my_modules.protocols.confirm_link_update_modal.revert_title'),
      message: t('my_modules.protocols.confirm_link_update_modal.revert_message'),
      btn_text: t('my_modules.protocols.confirm_link_update_modal.revert_btn_text'),
      url: revert_protocol_path(@protocol)
    }
  end

  def update_from_parent_modal
    render json: {
      title: t('my_modules.protocols.confirm_link_update_modal.update_self_title'),
      message: t('my_modules.protocols.confirm_link_update_modal.update_self_message'),
      btn_text: t('my_modules.protocols.confirm_link_update_modal.update_self_btn_text'),
      url: update_from_parent_protocol_path(@protocol)
    }
  end

  def load_from_repository_datatable
    @protocol = Protocol.find_by_id(params[:id])
    render json: ::LoadFromRepositoryProtocolsDatatable.new(
      view_context,
      @protocol.team,
      current_user
    )
  end

  def load_from_repository_modal
    render json: {
      html: render_to_string(partial: 'my_modules/protocols/load_from_repository_modal_body', formats: :html)
    }
  end

  def protocol_status_bar
    render json: {
      html: render_to_string(partial: 'my_modules/protocols/protocol_status_bar', formats: :html)
    }
  end

  def version_comment
    render json: { version_comment: @protocol.version_comment }
  end

  def update_version_comment
    if @protocol.update(version_comment: params.require(:protocol)[:version_comment])
      log_activity(:protocol_template_revision_notes_updated,
                   nil,
                   protocol: @protocol.id)
      render json: { version_comment: @protocol.version_comment }
    else
      render json: { errors: @protocol.errors }, status: :unprocessable_entity
    end
  end

  def permissions
    if stale?([@protocol, @protocol.team.user_assignments])
      render json: {
        copyable: can_clone_protocol_in_repository?(@protocol),
        archivable: can_archive_protocol_in_repository?(@protocol),
        restorable: can_restore_protocol_in_repository?(@protocol),
        readable: can_read_protocol_in_repository?(@protocol)
      }
    end
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::ProtocolsService.new(
          current_user,
          protocol_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
  end

  def import_docx
    return render_403 unless Protocol.docx_parser_enabled?

    temp_files_ids = []
    params[:files].each do |file|
      temp_file = TempFile.new(session_id: request.session_options[:id], file: file)

      if temp_file.save
        TempFile.destroy_obsolete(temp_file.id)
        temp_files_ids << temp_file.id
      end
    end
    @job = Protocols::DocxImportJob.perform_later(temp_files_ids, user_id: current_user.id, team_id: current_team.id)
    render json: { job_id: @job.job_id }
  end

  def user_roles
    render json: { data: user_roles_collection(Protocol.new).map(&:reverse) }
  end

  private

  def set_importer
    case params.dig('protocol', 'elnVersion')
    when '1.0'
      @importer = ProtocolsImporter.new(current_user, current_team)
    when '1.1'
      @importer = ProtocolsImporterV2.new(current_user, current_team)
    end
  end

  def export_protocol_file_name(protocols)
    protocol_name = get_protocol_name(protocols[0])

    if protocols.count == 1
      file_name = 'protocol.eln'
      unless protocol_name.nil?
        escaped_name = protocol_name.gsub(/[^0-9a-zA-Z\-.,_]/i, '_')
                                    .downcase[0..Constants::NAME_MAX_LENGTH]
        file_name = escaped_name + '.eln' unless escaped_name.blank?
      end
    elsif protocols.length > 1
      file_name = 'protocols.eln'
    end
    file_name
  end

  def valid_protocol_json(json)
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
  end

  def move_protocols(action)
    Protocol.transaction do
      @protocols.find_each do |protocol|
        protocol = protocol.parent if protocol.parent_id
        unless protocol.method(action).call(current_user)
          raise StandardError, protocol.errors&.messages&.values&.join(' ') || I18n.t('errors.general')
        end
      end
    end
    render json: { message: t("protocols.index.#{action}_flash_html", count: @protocols.size) }
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { message: e.message }, status: :unprocessable_entity
  end

  def set_inline_name_editing
    return unless @protocol.initial_draft?
    return unless can_manage_protocol_draft_in_repository?(@protocol)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'protocol',
      item_id: @protocol.id,
      field_to_udpate: 'name',
      path_to_update: name_protocol_path(@protocol)
    }
  end

  def load_team_and_type
    @current_team = current_team
    # :public, :private or :archive
    @type = (params[:type] || 'active').to_sym
  end

  def check_view_all_permissions
    load_team_and_type

    render_403 unless can_read_team?(@current_team)
  end

  def check_view_permissions
    @protocol = Protocol.find_by(id: params[:id])
    current_team_switch(@protocol.team) if current_team != @protocol.team
    unless @protocol.present? &&
           (can_read_protocol_in_module?(@protocol) ||
           can_read_protocol_in_repository?(@protocol) ||
           (@protocol.in_repository? && can_manage_team?(@protocol.team)))
      render_403
    end
  end

  def check_create_permissions
    load_team_and_type

    if !can_create_protocols_in_repository?(@current_team) || @type == :archive
      render_403
    end
  end

  def check_clone_permissions
    load_team_and_type
    protocol = Protocol.find_by(id: params[:protocol_ids])
    @original = protocol.latest_published_version_or_self

    if @original.blank? ||
       !can_clone_protocol_in_repository?(@original) || @type == :archive
      render_403
    end
  end

  def check_manage_permissions
    @protocol = Protocol.find_by(id: params[:id])
    render_403 unless @protocol.present? &&
                      (can_manage_protocol_in_module?(@protocol) ||
                       can_manage_protocol_draft_in_repository?(@protocol))
  end

  def check_manage_with_read_protocol_permissions
    @protocol = Protocol.find_by(id: params[:id])
    render_403 unless @protocol.present? && @protocol.parent.present? &&
                      (can_manage_protocol_in_module?(@protocol) &&
                       can_read_protocol_in_repository?(@protocol.parent))
  end

  def check_save_as_draft_permissions
    @protocol = Protocol.find_by(id: params[:id])
    render_403 unless @protocol.present? && can_save_protocol_version_as_draft?(@protocol)
  end

  def check_delete_draft_permissions
    @protocol = Protocol.find_by(id: params[:id])
    render_403 unless @protocol.present? &&
                      can_delete_protocol_draft_in_repository?(@protocol)
  end

  def check_archive_all_in_repository_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_archive_protocol_in_repository?(protocol)
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        break
      end
    end
  end

  def check_restore_all_in_repository_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_restore_protocol_in_repository?(protocol)
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        break
      end
    end
  end

  def check_load_from_repository_views_permissions
    @protocol = Protocol.find_by_id(params[:id])

    render_403 if @protocol.blank? || !can_read_protocol_in_module?(@protocol)
  end

  def check_publish_permission
    @protocol = Protocol.find_by(id: params[:id])

    render_403 if @protocol.blank? || !can_publish_protocol_in_repository?(@protocol)
  end

  def check_load_from_repository_permissions
    @protocol = Protocol.find_by(id: params[:id])
    @source = Protocol.find_by(id: params[:source_id])&.latest_published_version_or_self

    render_403 unless @protocol.present? && @source.present? &&
                      (can_manage_protocol_in_module?(@protocol) &&
                       can_read_protocol_in_repository?(@source))
  end

  def check_copy_to_repository_permissions
    @protocol = Protocol.find_by(id: params[:id])
    @my_module = @protocol.my_module

    render_403 unless @my_module.present? &&
                      (can_read_protocol_in_module?(@protocol) ||
                       can_create_protocols_in_repository?(@protocol.team))
  end

  def check_import_permissions
    @protocol_json = params[:protocol]
    @team = Team.find(params[:team_id])
    render_403 unless @protocol_json.present? && @team.present? && can_create_protocols_in_repository?(@team)
  end

  def check_export_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    render_403 if @protocols.blank?
    @protocols.each do |p|
      render_403 unless can_read_protocol_in_module?(p) ||
                        can_read_protocol_in_repository?(p)
    end
  end

  def copy_to_repository_params
    params.require(:protocol).permit(:name, :protocol_type)
  end

  def create_params
    params.require(:protocol).permit(:name, :default_public_user_role_id, :visibility)
  end

  def check_protocolsio_import_permissions
    render_403 unless can_create_protocols_in_repository?(current_team)
  end

  def log_activity(type_of, project = nil, message_items = {})
    message_items = { protocol: @protocol&.id }.merge(message_items)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @protocol,
            team: @protocol.team,
            project: project,
            message_items: message_items)
  end

  def protocol_annotation_notification(old_text)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @protocol.description,
      subject: @protocol,
      title: t('notifications.protocol_description_annotation_title',
               user: current_user.full_name,
               protocol: @protocol.name),
      message: t('notifications.protocol_description_annotation_message_html',
                 protocol: link_to(@protocol.name, protocol_url(@protocol)))
    )
  end

  def set_breadcrumbs_items
    @breadcrumbs_items = []
    archived_branch = params[:type] == 'archived' || @protocol&.archived?

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.templates'),
                              archived: archived_branch
                            })

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.protocols'),
                              url: archived_branch ? protocols_path(type: :archived) : protocols_path,
                              archived: archived_branch
                            })

    if @protocol
      @breadcrumbs_items.push({
                                label: @protocol.name,
                                url: protocol_path(@protocol),
                                archived: archived_branch
                              })
    end

    @breadcrumbs_items.each do |item|
      item[:label] = "(A) #{item[:label]}" if item[:archived]
    end
  end
end
