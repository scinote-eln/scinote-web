
class ProtocolsController < ApplicationController
  include RenamingUtil
  include ProtocolsImporter
  include ProtocolsExporter
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include ProtocolsIoHelper
  include TeamsHelper
  include CommentHelper

  before_action :check_create_permissions, only: %i(
    create_new_modal
    create
  )
  before_action :check_clone_permissions, only: [:clone]
  before_action :check_view_permissions, only: %i(
    protocol_status_bar
    updated_at_label
    preview
    linked_children
    linked_children_datatable
  )
  before_action :check_view_all_permissions, only: %i(
    index
    datatable
  )
  # For update_from_parent and update_from_parent_modal we don't need to check
  # read permission for the parent protocol
  before_action :check_manage_permissions, only: %i(
    edit
    update_keywords
    update_description
    update_name
    update_authors
    edit_name_modal
    edit_keywords_modal
    edit_authors_modal
    edit_description_modal
    unlink
    unlink_modal
    revert
    revert_modal
    update_from_parent
    update_from_parent_modal
  )
  before_action :check_manage_parent_in_repository_permissions, only: %i(
    update_parent
    update_parent_modal
  )
  before_action :check_manage_all_in_repository_permissions, only:
    %i(make_private publish archive)
  before_action :check_restore_all_in_repository_permissions, only: :restore
  before_action :check_load_from_repository_views_permissions, only: %i(
    load_from_repository_modal
    load_from_repository_datatable
  )
  before_action :check_load_from_repository_permissions, only: [
    :load_from_repository
  ]
  before_action :check_load_from_file_permissions, only: [
    :load_from_file
  ]
  before_action :check_copy_to_repository_permissions, only: %i(
    copy_to_repository
    copy_to_repository_modal
  )
  before_action :check_import_permissions, only: :import
  before_action :check_export_permissions, only: :export

  before_action :check_protocolsio_import_permissions,
                only: %i(protocolsio_import_create protocolsio_import_save)

  def index; end

  def datatable
    respond_to do |format|
      format.json do
        render json: ::ProtocolsDatatable.new(
          view_context,
          @current_team,
          @type,
          current_user
        )
      end
    end
  end

  def preview
    respond_to do |format|
      format.json do
        render json: {
          title: I18n.t('protocols.index.preview.title',
                        protocol: escape_input(@protocol.name)),
          html: render_to_string(
            partial: 'protocols/index/protocol_preview_modal_body.html.erb',
            locals: { protocol: @protocol }
          ),
          footer: render_to_string(
            partial: 'protocols/index/protocol_preview_modal_footer.html.erb',
            locals: { protocol: @protocol }
          )
        }
      end
    end
  end

  def recent_protocols
    render json: Protocol.recent_protocols(
      current_user,
      current_team,
      Constants::RECENT_PROTOCOL_LIMIT
    ).select(:id, :name)
  end

  def linked_children
    respond_to do |format|
      format.json do
        render json: {
          title: I18n.t('protocols.index.linked_children.title',
                        protocol: escape_input(@protocol.name)),
          html: render_to_string(partial: 'protocols/index/linked_children_modal_body.html.erb',
                                   locals: { protocol: @protocol })
        }
      end
    end
  end

  def linked_children_datatable
    respond_to do |format|
      format.json do
        render json: ::ProtocolLinkedChildrenDatatable.new(
          view_context,
          @protocol,
          current_user,
          self
        )
      end
    end
  end

  def make_private
    move_protocol('make_private')
  end

  def publish
    move_protocol('publish')
  end

  def archive
    move_protocol('archive')
  end

  def restore
    move_protocol('restore')
  end

  def edit
    # Switch to correct team
    current_team_switch(@protocol.team)
  end

  def update_keywords
    respond_to do |format|
      # sanitize user input
      if params[:keywords]
        params[:keywords].collect! do |keyword|
          escape_input(keyword)
        end
      end
      if @protocol.update_keywords(params[:keywords])
        format.json do
          log_activity(:edit_keywords_in_protocol_repository, nil, protocol: @protocol.id)
          render json: { status: :ok }
        end
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def update_authors
    if @protocol.update(authors: params.require(:protocol)[:authors])
      log_activity(:edit_authors_in_protocol_repository, nil, protocol: @protocol.id)
      render json: {}, status: :ok
    else
      render json: @protocol.errors, status: :unprocessable_entity
    end
  end

  def update_name
    if @protocol.update(name: params.require(:protocol)[:name])
      render json: {}, status: :ok
    else
      render json: @protocol.errors, status: :unprocessable_entity
    end
  end

  def update_description
    respond_to do |format|
      format.json do
        if @protocol.update(description: params.require(:protocol)[:description])
          log_activity(:edit_description_in_protocol_repository, nil, protocol: @protocol.id)
          TinyMceAsset.update_images(@protocol, params[:tiny_mce_images], current_user)
          render json: {
            html: custom_auto_link(
              @protocol.tinymce_render(:description),
              simple_format: false,
              tags: %w(img),
              team: current_team)
          }
        else
          render json: @protocol.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def create
    @protocol = Protocol.new(
      team: @current_team,
      protocol_type: Protocol.protocol_types[@type == :public ? :in_repository_public : :in_repository_private],
      added_by: current_user
    )
    @protocol.assign_attributes(create_params)

    ts = Time.now
    @protocol.record_timestamps = false
    @protocol.created_at = ts
    @protocol.updated_at = ts
    @protocol.published_on = ts if @type == :public

    respond_to do |format|
      if @protocol.save

        log_activity(:create_protocol_in_repository, nil, protocol: @protocol.id)

        TinyMceAsset.update_images(@protocol, params[:tiny_mce_images], current_user)
        format.json do
          render json: {
            url: edit_protocol_path(
              @protocol,
              team: @current_team,
              type: @type
            )
          }
        end
      else
        format.json do
          render json: @protocol.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def clone
    cloned = nil
    Protocol.transaction do
      begin
        cloned = @original.deep_clone_repository(current_user)
      rescue Exception
        raise ActiveRecord:: Rollback
      end
    end
    respond_to do |format|
      if !cloned.nil?
        flash[:success] = t(
          'protocols.index.clone.success_flash',
          original: @original.name,
          new: cloned.name
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      else
        flash[:error] = t(
          'protocols.index.clone.error_flash',
          original: @original.name
        )
        flash.keep(:error)
        format.json { render json: {}, status: :bad_request }
      end
    end
  end

  def copy_to_repository
    link_protocols = params[:link] &&
                     can_manage_protocol_in_module?(@protocol) &&
                     can_create_protocols_in_repository?(@protocol.team)
    respond_to do |format|
      transaction_error = false
      Protocol.transaction do
        @new = @protocol.copy_to_repository(
          copy_to_repository_params[:name],
          copy_to_repository_params[:protocol_type],
          link_protocols,
          current_user
        )
      rescue StandardError
        transaction_error = true
        raise ActiveRecord:: Rollback
      end

      if transaction_error
        # Bad request error
        format.json do
          render json: {
            message: t('my_modules.protocols.copy_to_repository_modal.error_400')
          },
          status: :bad_request
        end
      elsif @new.invalid?
        # Render errors
        format.json do
          render json: @new.errors,
          status: :unprocessable_entity
        end
      else
        # Everything good, render 200
        format.json { render json: { refresh: link_protocols }, status: :ok }
      end
    end
  end

  def unlink
    respond_to do |format|
      transaction_error = false
      Protocol.transaction do
        begin
          @protocol.unlink
        rescue Exception
          transaction_error = true
          raise ActiveRecord:: Rollback
        end
      end

      if transaction_error
        # Bad request error
        format.json do
          render json: {
            message: t('my_modules.protocols.unlink_error')
          },
          status: :bad_request
        end
      else
        # Everything good, display flash & render 200
        flash[:success] = t(
          'my_modules.protocols.unlink_flash'
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def revert
    respond_to do |format|
      if @protocol.can_destroy?
        transaction_error = false
        Protocol.transaction do
          begin
            # Revert is basically update from parent
            @protocol.update_from_parent(current_user)
          rescue Exception
            transaction_error = true
            raise ActiveRecord:: Rollback
          end
        end

        if transaction_error
          # Bad request error
          format.json do
            render json: {
              message: t('my_modules.protocols.revert_error')
            },
            status: :bad_request
          end
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
          format.json { render json: {}, status: :ok }
        end
      else
        format.json do
          render json: {
            message: t('my_modules.protocols.revert_error_locked')
          }, status: :bad_request
        end
      end
    end
  end

  def update_parent
    respond_to do |format|
      if @protocol.parent.can_destroy?
        transaction_error = false
        Protocol.transaction do
          begin
            @protocol.update_parent(current_user)
          rescue Exception
            transaction_error = true
            raise ActiveRecord:: Rollback
          end
        end

        if transaction_error
          # Bad request error
          format.json do
            render json: {
              message: t('my_modules.protocols.update_parent_error')
            },
            status: :bad_request
          end
        else
          # Everything good, record activity, display flash & render 200
          log_activity(:update_protocol_in_repository_from_task,
                       @protocol.my_module.experiment.project,
                       my_module: @protocol.my_module.id,
                       protocol_repository: @protocol.parent.id)
          flash[:success] = t(
            'my_modules.protocols.update_parent_flash'
          )
          flash.keep(:success)
          format.json { render json: {}, status: :ok }
        end
      else
        format.json do
          render json: {
            message: t('my_modules.protocols.update_parent_error_locked')
          }, status: :bad_request
        end
      end
    end
  end

  def update_from_parent
    respond_to do |format|
      if @protocol.can_destroy?
        transaction_error = false
        Protocol.transaction do
          begin
            @protocol.update_from_parent(current_user)
          rescue Exception
            transaction_error = true
            raise ActiveRecord:: Rollback
          end
        end

        if transaction_error
          # Bad request error
          format.json do
            render json: {
              message: t('my_modules.protocols.update_from_parent_error')
            },
            status: :bad_request
          end
        else
          # Everything good, display flash & render 200
          log_activity(:update_protocol_in_task_from_repository,
                       @protocol.my_module.experiment.project,
                       my_module: @protocol.my_module.id,
                       protocol_repository: @protocol.parent.id)
          flash[:success] = t(
            'my_modules.protocols.update_from_parent_flash'
          )
          flash.keep(:success)
          format.json { render json: {}, status: :ok }
        end
      else
        format.json do
          render json: {
            message: t('my_modules.protocols.update_from_parent_error_locked')
          }, status: :bad_request
        end
      end
    end
  end

  def load_from_repository
    respond_to do |format|
      if @protocol.can_destroy?
        transaction_error = false
        Protocol.transaction do
          begin
            @protocol.load_from_repository(@source, current_user)
          rescue Exception
            transaction_error = true
            raise ActiveRecord:: Rollback
          end
        end

        if transaction_error
          # Bad request error
          format.json do
            render json: {
              message: t('my_modules.protocols.load_from_repository_error')
            },
            status: :bad_request
          end
        else
          # Everything good, record activity, display flash & render 200
          log_activity(:load_protocol_to_task_from_repository,
                       @protocol.my_module.experiment.project,
                       my_module: @protocol.my_module.id,
                       protocol_repository: @protocol.parent.id)
          flash[:success] = t('my_modules.protocols.load_from_repository_flash')
          flash.keep(:success)
          format.json { render json: {}, status: :ok }
        end
      else
        format.json do
          render json: {
            message: t('my_modules.protocols.load_from_repository_error_locked')
          }, status: :bad_request
        end
      end
    end
  end

  def load_from_file
    # This is actually very similar to import
    respond_to do |format|
      if @protocol.can_destroy?
        transaction_error = false
        Protocol.transaction do
          begin
            import_into_existing(
              @protocol, @protocol_json, current_user, current_team
            )
          rescue Exception
            transaction_error = true
            raise ActiveRecord:: Rollback
          end
        end

        if transaction_error
          format.json do
            render json: { status: :error }, status: :bad_request
          end
        else
          # Everything good, record activity, display flash & render 200
          log_activity(:load_protocol_to_task_from_file,
                       @protocol.my_module.experiment.project,
                       my_module: @my_module.id)
          flash[:success] = t(
            'my_modules.protocols.load_from_file_flash'
          )
          flash.keep(:success)
          format.json do
            render json: { status: :ok }, status: :ok
          end
        end
      else
        format.json do
          render json: { status: :locked }, status: :bad_request
        end
      end
    end
  end

  def import
    protocol = nil
    respond_to do |format|
      transaction_error = false
      Protocol.transaction do
        begin
          protocol =
            import_new_protocol(@protocol_json, @team, @type, current_user)
        rescue StandardError => ex
          Rails.logger.error ex.message
          transaction_error = true
          raise ActiveRecord:: Rollback
        end
      end

      p_name =
        if @protocol_json['name'].present? && !@protocol_json['name'].empty?
          escape_input(@protocol_json['name'])
        else
          t('protocols.index.no_protocol_name')
        end
      if transaction_error
        format.json do
          render json: { name: p_name, status: :bad_request }, status: :bad_request
        end
      else
        Activities::CreateActivityService
          .call(activity_type: :import_protocol_in_repository,
                owner: current_user,
                subject: protocol,
                team: current_team,
                message_items: {
                  protocol: protocol.id
                })

        format.json do
          render json: {
            name: escape_input(p_name), new_name: escape_input(protocol.name), status: :ok
          },
          status: :ok
        end
      end
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
    Rails.logger.error(e.message)
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
      sanitize_input(not_null(params['protocol']['name']))
    )
    # since scinote only has description field, and protocols.io has many others
    # ,here i am putting everything important from protocols.io into description
    @db_json['authors'] = pio_eval_title_len(
      sanitize_input(not_null(params['protocol']['authors']))
    )
    @db_json['created_at'] = pio_eval_title_len(
      sanitize_input(not_null(params['protocol']['created_at']))
    )
    @db_json['updated_at'] = pio_eval_title_len(
      sanitize_input(not_null(params['protocol']['last_modified']))
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
          protocol = import_new_protocol(
            @db_json, current_team, params[:type].to_sym, current_user
          )
        rescue Exception
          transaction_error = true
          raise ActiveRecord:: Rollback
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
    respond_to do |format|
      format.html do
        z_output_stream = Zip::OutputStream.write_buffer do |ostream|
          ostream.put_next_entry('scinote.xml')
          ostream.print(generate_envelope_xml(@protocols))
          ostream.put_next_entry('scinote.xsd')
          ostream.print(generate_envelope_xsd)
          ostream.put_next_entry('eln.xsd')
          ostream.print(generate_eln_xsd)

          # Create folder and xml file for each protocol and populate it
          @protocols.each do |protocol|
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
                end
              end
              ostream = step.tiny_mce_assets.save_to_eln(ostream, step_dir)
            end
          end
        end
        z_output_stream.rewind

        protocol_name = get_protocol_name(@protocols[0])

        # Now generate filename of the archive and send file to user
        if @protocols.count == 1
          # Try to construct an OS-safe file name
          file_name = 'protocol.eln'
          unless protocol_name.nil?
            escaped_name = protocol_name.gsub(/[^0-9a-zA-Z\-.,_]/i, '_')
                                        .downcase[0..Constants::NAME_MAX_LENGTH]
            file_name = escaped_name + '.eln' unless escaped_name.empty?
          end
        elsif @protocols.length > 1
          file_name = 'protocols.eln'
        end

        @protocols.each do |p|
          if params[:my_module_id]
            my_module = MyModule.find(params[:my_module_id])
            Activities::CreateActivityService
              .call(activity_type: :export_protocol_from_task,
                    owner: current_user,
                    project: my_module.experiment.project,
                    subject: my_module,
                    team: current_team,
                    message_items: {
                      my_module: params[:my_module_id].to_i
                    })
          else
            Activities::CreateActivityService
              .call(activity_type: :export_protocol_in_repository,
                    owner: current_user,
                    subject: p,
                    team: current_team,
                    message_items: {
                      protocol: p.id
                    })
          end
        end

        send_data(z_output_stream.read, filename: file_name)
      end
    end
  end

  def unlink_modal
    respond_to do |format|
      format.json do
        render json: {
          title: t('my_modules.protocols.confirm_link_update_modal.unlink_title'),
          message: t('my_modules.protocols.confirm_link_update_modal.unlink_message'),
          btn_text: t('my_modules.protocols.confirm_link_update_modal.unlink_btn_text'),
          url: unlink_protocol_path(@protocol)
        }
      end
    end
  end

  def revert_modal
    respond_to do |format|
      format.json do
        render json: {
          title: t('my_modules.protocols.confirm_link_update_modal.revert_title'),
          message: t('my_modules.protocols.confirm_link_update_modal.revert_message'),
          btn_text: t('my_modules.protocols.confirm_link_update_modal.revert_btn_text'),
          url: revert_protocol_path(@protocol)
        }
      end
    end
  end

  def update_parent_modal
    respond_to do |format|
      format.json do
        render json: {
          title: t('my_modules.protocols.confirm_link_update_modal.update_parent_title'),
          message: t('my_modules.protocols.confirm_link_update_modal.update_parent_message'),
          btn_text: t('general.update'),
          url: update_parent_protocol_path(@protocol)
        }
      end
    end
  end

  def update_from_parent_modal
    respond_to do |format|
      format.json do
        render json: {
          title: t('my_modules.protocols.confirm_link_update_modal.update_self_title'),
          message: t('my_modules.protocols.confirm_link_update_modal.update_self_message'),
          btn_text: t('general.update'),
          url: update_from_parent_protocol_path(@protocol)
        }
      end
    end
  end

  def load_from_repository_datatable
    @protocol = Protocol.find_by_id(params[:id])
    @type = (params[:type] || 'public').to_sym
    respond_to do |format|
      format.json do
        render json: ::LoadFromRepositoryProtocolsDatatable.new(
          view_context,
          @protocol.team,
          @type,
          current_user
        )
      end
    end
  end

  def load_from_repository_modal
    @protocol = Protocol.find_by_id(params[:id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string({
            partial: "my_modules/protocols/load_from_repository_modal_body.html.erb"
          })
        }
      end
    end
  end

  def copy_to_repository_modal
    @new = Protocol.new
    @original = Protocol.find(params[:id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string({
            partial: "my_modules/protocols/copy_to_repository_modal_body.html.erb"
          })
        }
      end
    end
  end

  def protocol_status_bar
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string({
            partial: "my_modules/protocols/protocol_status_bar.html.erb"
          })
        }
      end
    end
  end

  def updated_at_label
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string({
            partial: "protocols/header/updated_at_label.html.erb"
          })
        }
      end
    end
  end

  def create_new_modal
    @new_protocol = Protocol.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string({
            partial: "protocols/index/create_new_modal_body.html.erb"
          })
        }
      end
    end
  end

  def edit_name_modal
    respond_to do |format|
      format.json do
        render json: {
          title: I18n.t('protocols.header.edit_name_modal.title',
                        protocol: escape_input(@protocol.name)),
                        html: render_to_string({
                          partial: "protocols/header/edit_name_modal_body.html.erb"
                        })
        }
      end
    end
  end

  def edit_keywords_modal
    respond_to do |format|
      format.json do
        render json: {
          title: I18n.t('protocols.header.edit_keywords_modal.title',
                        protocol: escape_input(@protocol.name)),
                        html: render_to_string({
                          partial: "protocols/header/edit_keywords_modal_body.html.erb"
                        }),
          keywords: @protocol.team.protocol_keywords_list
        }
      end
    end
  end

  def edit_authors_modal
    respond_to do |format|
      format.json do
        render json: {
          title: I18n.t('protocols.header.edit_authors_modal.title',
                        protocol: escape_input(@protocol.name)),
                        html: render_to_string({
                          partial: "protocols/header/edit_authors_modal_body.html.erb"
                        })
        }
      end
    end
  end

  def edit_description_modal
    respond_to do |format|
      format.json do
        render json: {
          title: I18n.t('protocols.header.edit_description_modal.title',
                        protocol: escape_input(@protocol.name)),
          html: render_to_string({
            partial: "protocols/header/edit_description_modal_body.html.erb"
          })
        }
      end
    end
  end

  private

  def valid_protocol_json(json)
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
  end

  def move_protocol(action)
    rollbacked = false
    results = []
    begin
      Protocol.transaction do
        @protocols.find_each do |protocol|
          result = {
            name: protocol.name
          }

          success = protocol.method(action).call(current_user)

          # Try renaming protocol
          unless success
            rename_record(protocol, :name)
            success = protocol.method(action).call(current_user)
          end

          result[:new_name] = protocol.name
          result[:type] = protocol.protocol_type
          result[:success] = success
          results << result
        end
      end
    rescue
      rollbacked = true
    end

    respond_to do |format|
      if rollbacked
        format.json do
          render json: {}, status: :bad_request
        end
      else
        format.json do
          render json: {
            html: render_to_string({
              partial: "protocols/index/results_modal_body.html.erb",
              locals: { results: results, en_action: "#{action}_results" }
            })
          }
        end
      end
    end
  end

  def load_team_and_type
    @current_team = current_team
    # :public, :private or :archive
    @type = (params[:type] || 'public').to_sym
  end

  def check_view_all_permissions
    load_team_and_type

    render_403 unless can_read_team?(@current_team)
  end

  def check_view_permissions
    @protocol = Protocol.find_by_id(params[:id])
    unless @protocol.present? &&
           (can_read_protocol_in_module?(@protocol) ||
           can_read_protocol_in_repository?(@protocol))
      respond_to { |f| f.json { render json: {}, status: :unauthorized } }
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
    @original = Protocol.find_by_id(params[:id])

    if @original.blank? ||
       !can_clone_protocol_in_repository?(@original) || @type == :archive
      render_403
    end
  end

  def check_manage_permissions
    @protocol = Protocol.find_by_id(params[:id])
    render_403 unless @protocol.present? &&
                      (can_manage_protocol_in_module?(@protocol) ||
                       can_manage_protocol_in_repository?(@protocol))
  end

  def check_manage_parent_in_repository_permissions
    @protocol = Protocol.find_by_id(params[:id])
    render_403 unless @protocol.present? &&
                      can_read_protocol_in_module?(@protocol) &&
                      can_manage_protocol_in_repository?(@protocol.parent)
  end

  def check_manage_all_in_repository_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_manage_protocol_in_repository?(protocol)
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

  def check_load_from_repository_permissions
    @protocol = Protocol.find_by_id(params[:id])
    @source = Protocol.find_by_id(params[:source_id])

    render_403 unless @protocol.present? && @source.present? &&
                      (can_manage_protocol_in_module?(@protocol) ||
                       can_read_protocol_in_repository?(@source))
  end

  def check_load_from_file_permissions
    @protocol_json = params[:protocol]
    @protocol = Protocol.find_by_id(params[:id])
    @my_module = @protocol.my_module

    if @protocol_json.blank? ||
       @protocol.blank? ||
       @my_module.blank? ||
       !can_manage_protocol_in_module?(@protocol)
      render_403
    end
  end

  def check_copy_to_repository_permissions
    @protocol = Protocol.find_by_id(params[:id])
    @my_module = @protocol.my_module

    render_403 unless @my_module.present? &&
                      (can_read_protocol_in_module?(@protocol) ||
                       can_create_protocols_in_repository?(@protocol.team))
  end

  def check_import_permissions
    @protocol_json = params[:protocol]
    @team = Team.find(params[:team_id])
    @type = params[:type] ? params[:type].to_sym : nil
    unless @protocol_json.present? && @team.present? &&
           (@type == :public || @type == :private) &&
           can_create_protocols_in_repository?(@team)
      render_403
    end
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
    params.require(:protocol).permit(:name)
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
            team: current_team,
            project: project,
            message_items: message_items)
  end
end
