
class ProtocolsController < ApplicationController
  include RenamingUtil
  include ProtocolsImporter
  include ProtocolsExporter
  include InputSanitizeHelper
  include ProtocolsIoTableHelper

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
  before_action :check_edit_permissions, only: %i(
    edit
    update_metadata
    update_keywords
    edit_name_modal
    edit_keywords_modal
    edit_authors_modal
    edit_description_modal
  )
  before_action :check_view_all_permissions, only: %i(
    index
    datatable
  )
  before_action :check_unlink_permissions, only: %i(
    unlink
    unlink_modal
  )
  before_action :check_revert_permissions, only: %i(
    revert
    revert_modal
  )
  before_action :check_update_parent_permissions, only: %i(
    update_parent
    update_parent_modal
  )
  before_action :check_update_from_parent_permissions, only: %i(
    update_from_parent
    update_from_parent_modal
  )
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
  before_action :check_make_private_permissions, only: [:make_private]
  before_action :check_publish_permissions, only: [:publish]
  before_action :check_archive_permissions, only: [:archive]
  before_action :check_restore_permissions, only: [:restore]
  before_action :check_import_permissions, only: [:import]
  before_action :check_export_permissions, only: [:export]

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

  def edit; end

  def update_metadata
    @protocol.record_timestamps = false
    @protocol.assign_attributes(metadata_params)

    respond_to do |format|
      if @protocol.save
        format.json do
          render json: {
            updated_at_label: render_to_string(
              partial: 'protocols/header/updated_at_label.html.erb'
            ),
            name_label: render_to_string(
              partial: 'protocols/header/name_label.html.erb'
            ),
            authors_label: render_to_string(
              partial: 'protocols/header/authors_label.html.erb'
            ),
            description_label: render_to_string(
              partial: 'protocols/header/description_label.html.erb'
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

  def update_keywords
    respond_to do |format|
      # sanitize user input
      params[:keywords].collect! do |keyword|
        escape_input(keyword)
      end
      if @protocol.update_keywords(params[:keywords])
        format.json do
          render json: {
            updated_at_label: render_to_string(
              partial: 'protocols/header/updated_at_label.html.erb'
            ),
            keywords_label: render_to_string(
              partial: 'protocols/header/keywords_label.html.erb'
            )
          }
        end
      else
        format.json { render json: {}, status: :unprocessable_entity }
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
    link_protocols = can_link_copied_protocol_in_repository(@protocol) && params[:link]
    respond_to do |format|
      transaction_error = false
      Protocol.transaction do
        begin
          @new = @protocol.copy_to_repository(
            copy_to_repository_params[:name],
            copy_to_repository_params[:protocol_type],
            link_protocols,
            current_user
          )
        rescue Exception
          transaction_error = true
          raise ActiveRecord:: Rollback
        end
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
          Activity.create(
            type_of: :revert_protocol,
            project: @protocol.my_module.experiment.project,
            experiment: @protocol.my_module.experiment,
            my_module: @protocol.my_module,
            user: current_user,
            message: I18n.t(
              'activities.revert_protocol',
              user: current_user.full_name,
              protocol: @protocol.name
            )
          )
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
          Activity.create(
            type_of: :load_protocol_from_repository,
            project: @protocol.my_module.experiment.project,
            experiment: @protocol.my_module.experiment,
            my_module: @protocol.my_module,
            user: current_user,
            message: I18n.t(
              'activities.load_protocol_from_repository',
              user: current_user.full_name,
              protocol: @source.name
            )
          )
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
          Activity.create(
            type_of: :load_protocol_from_file,
            project: @protocol.my_module.experiment.project,
            experiment: @protocol.my_module.experiment,
            my_module: @protocol.my_module,
            user: current_user,
            message: I18n.t(
              'activities.load_protocol_from_file',
              user: current_user.full_name,
              protocol: @protocol_json[:name]
            )
          )
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
          protocol = import_new_protocol(@protocol_json, @team, @type, current_user)
        rescue Exception
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
        format.json do
          render json: {
            name: p_name, new_name: protocol.name, status: :ok
          },
          status: :ok
        end
      end
    end
  end

  def protocolsio_import_create
    @protocolsio_too_big = false
    file_size = File.size(params[:json_file].path)
    if file_size / 1000 > Constants::FILE_MAX_SIZE_MB
      @protocolsio_too_big = true
      respond_to do |format|
        format.js {}
        # if file is too big, default to the js.erb file,
        # named the same as this controller
        # where a javascript alert is called
      end
    end
    json_file_contents = File.read(params[:json_file].path)
    json_file_contents.gsub! '\"', "'"
    # escaped double quotes too stressfull, html works with single quotes too
    # json double quotes dont get escaped since they dont match \"
    @json_object = JSON.parse(json_file_contents)
    @protocol = Protocol.new
    respond_to do |format|
      format.js {} # go to the js.erb file named the same as this controller,
      # where a preview modal is rendered,
      # and some modals get closed and opened
    end
  end

  def protocolsio_import_save
    @json_object = JSON.parse(params['json_object'])
    @db_json = {}
    @db_json['name'] = sanitize_input(params['protocol']['name'])
    # since scinote only has description field, and protocols.io has many others
    # ,here i am putting everything important from protocols.io into description
    @db_json['authors'] = sanitize_input(params['protocol']['authors'])
    @db_json['created_at'] = sanitize_input(params['protocol']['created_at'])
    @db_json['updated_at'] = sanitize_input(params['protocol']['last_modified'])
    @db_json['steps'] = {}
    @db_json['steps'] = protocols_io_fill_step(@json_object, @db_json['steps'])
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
         { name: p_name, new_name: protocol.name, status: :ok },
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
            # Add assets to protocol folder
            next if protocol.steps.count <= 0
            protocol.steps.order(:id).each do |step|
              step_guid = get_guid(step.id)
              step_dir = "#{protocol_dir}/#{step_guid}"
              next if step.assets.count <= 0
              step.assets.order(:id).each do |asset|
                asset_guid = get_guid(asset.id)
                asset_file_name = asset_guid.to_s +
                                  File.extname(asset.file_file_name).to_s
                ostream.put_next_entry("#{step_dir}/#{asset_file_name}")
                input_file = asset.open
                ostream.print(input_file.read)
                input_file.close
              end
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

  # pio_stp_x means protocols io step (id of component) parser
  def pio_stp_1(iterating_key) # protocols io description parser
    br = '<br>'
    append = br + sanitize_input(iterating_key) + br if iterating_key.present?
    if iterating_key.blank?
      append = t('protocols.protocols_io_import.comp_append.missing_desc')
    end
    append
  end

  def pio_stp_6(iterating_key) # protocols io section(title) parser
    return sanitize_input(iterating_key) if iterating_key.present?
    t('protocols.protocols_io_import.comp_append.missing_step')
  end

  def pio_stp_17(iterating_key) # protocols io expected result parser
    if iterating_key.present?
      append =
        t('protocols.protocols_io_import.comp_append.expected_result') +
        sanitize_input(iterating_key) + '<br>'
      return append
    end
    ''
  end

  def pio_stp_8(iterating_key) # protocols io software package parser
    if iterating_key['name'] &&
       iterating_key['developer'] &&
       iterating_key['version'] &&
       iterating_key['link'] &&
       iterating_key['repository'] &&
       iterating_key['os_name'] &&
       iterating_key['os_version']
      append = t('protocols.protocols_io_import.comp_append.soft_packg.title') +
               sanitize_input(iterating_key['name']) +
               t('protocols.protocols_io_import.comp_append.soft_packg.dev') +
               sanitize_input(iterating_key['developer']) +
               t('protocols.protocols_io_import.comp_append.soft_packg.vers') +
               sanitize_input(iterating_key['version']) +
               t('protocols.protocols_io_import.comp_append.general_link') +
               sanitize_input(iterating_key['link']) +
               t('protocols.protocols_io_import.comp_append.soft_packg.repo') +
               sanitize_input(iterating_key['repository']) +
               t('protocols.protocols_io_import.comp_append.soft_packg.os') +
               sanitize_input(iterating_key['os_name']) + ' , ' +
               sanitize_input(iterating_key['os_version'])
      return append
    end
    ''
  end

  def pio_stp_9(iterating_key) # protocols io dataset parser
    if iterating_key['name'].present? &&
       iterating_key['link']
      append = t('protocols.protocols_io_import.comp_append.dataset.title') +
               sanitize_input(iterating_key['name']) +
               t('protocols.protocols_io_import.comp_append.general_link') +
               sanitize_input(iterating_key['link'])
      return append
    end
    ''
  end

  def pio_stp_15(iterating_key) # protocols io commands parser
    if iterating_key['name'].present? &&
       iterating_key['description'] &&
       iterating_key['os_name'] &&
       iterating_key['os_version']
      append = t('protocols.protocols_io_import.comp_append.command.title') +
               sanitize_input(iterating_key['name']) +
               t('protocols.protocols_io_import.comp_append.command.desc') +
               sanitize_input(iterating_key['description']) +
               t('protocols.protocols_io_import.comp_append.command.os') +
               sanitize_input(iterating_key['os_name']) +
               ' , ' + iterating_key['os_version']
      return append
    end
    ''
  end

  def pio_stp_18(iterating_key) # protocols io sub protocol parser
    if iterating_key['protocol_name'].present? &&
       iterating_key['full_name'] &&
       iterating_key['link']
      append =
        t(
          'protocols.protocols_io_import.comp_append.sub_protocol.title'
        ) +
        sanitize_input(iterating_key['protocol_name']) +
        t(
          'protocols.protocols_io_import.comp_append.sub_protocol.author'
        ) +
        sanitize_input(iterating_key['full_name']) +
        t('protocols.protocols_io_import.comp_append.general_link') +
        sanitize_input(iterating_key['link'])
      return append
    end
    ''
  end

  def pio_stp_19(iterating_key) # protocols io safety information parser
    if iterating_key['body'].present? &&
       iterating_key['link']
      append =
        t(
          'protocols.protocols_io_import.comp_append.safety_infor.title'
        ) +
        sanitize_input(iterating_key['body']) +
        t('protocols.protocols_io_import.comp_append.general_link') +
        sanitize_input(iterating_key['link'])
      return append
    end
    ''
  end

  def protocols_io_fill_desc(json_hash)
    description_array = %w[
      ( before_start warning guidelines manuscript_citation publish_date
      created_on vendor_name vendor_link keywords tags link )
    ]
    description_string =
      if json_hash['description'].present?
        '<strong>' + t('protocols.protocols_io_import.preview.prot_desc') +
          '</strong>' + sanitize_input(json_hash['description'].html_safe)
      else
        '<strong>' + t('protocols.protocols_io_import.preview.prot_desc') +
          '</strong>' + t('protocols.protocols_io_import.comp_append.missing_desc')
      end
    description_string += '<br>'
    description_array.each do |e|
      if e == 'created_on' && json_hash[e].present?
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ':  ' +
          sanitize_input(params['protocol']['created_at'].to_s) + '<br>'
      elsif e == 'tags' && json_hash[e].any? && json_hash[e] != ''
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ': '
        json_hash[e].each do |tag|
          description_string +=
            sanitize_input(tag['tag_name']) + ' , '
        end
        description_string += '<br>'
        # Since protocols description field doesnt show html,i just remove it
        # because its even messier (using Sanitize)
        # what this does is basically appends "FIELD NAME: "+" FIELD VALUE"
        # to description for various fields
      elsif json_hash[e].present?
        new_e = '<strong>' + e.humanize + '</strong>'
        description_string +=
          new_e.to_s + ':  ' +
          sanitize_input(json_hash[e].html_safe) + '<br>'
      end
    end
    description_string
  end

  def protocols_io_fill_step(original_json, newj)
    # newj = new json
    # (simple to map) id 1= step description, id 6= section (title),
    # id 17= expected result
    # (complex mapping with nested hashes) id 8 = software package,
    # id 9 = dataset, id 15 = command, id 18 = attached sub protocol
    # id 19= safety information ,
    # id 20= regents (materials, like scinote samples kind of)
    newj['0'] = {}
    newj['0']['position'] = 0
    newj['0']['name'] = 'Protocol info'
    newj['0']['tables'], table_str = protocolsio_string_to_table_element(
      sanitize_input(protocols_io_fill_desc(original_json).html_safe)
    )
    newj['0']['description'] = table_str
    original_json['steps'].each_with_index do |step, pos_orig| # loop over steps
      i = pos_orig + 1
      # position of step (first, second.... etc),
      newj[i.to_s] = {} # the json we will insert into db
      newj[i.to_s]['position'] = i
      newj[i.to_s]['description'] = '' unless newj[i.to_s].key?('description')
      newj[i.to_s]['name'] = '' unless newj[i.to_s].key?('name')
      step['components'].each do |key, value|
        # sometimes there are random index values as keys
        # instead of hashes, this is a workaround to that buggy json format
        key = value if value.class == Hash
        # append is the string that we append values into for description
        # pio_stp_x means protocols io step (id of component) parser
        case key['component_type_id']
        when '1'
          newj[i.to_s]['description'] += pio_stp_1(key['data'])
        when '6'
          newj[i.to_s]['name'] = pio_stp_6(key['data'])
        when '17'
          newj[i.to_s]['description'] += pio_stp_17(key['data'])
        when '8'
          newj[i.to_s]['description'] += pio_stp_8(key['source_data'])
        when '9'
          newj[i.to_s]['description'] += pio_stp_9(key['source_data'])
        when '15'
          newj[i.to_s]['description'] += pio_stp_15(key['source_data'])
        when '18'
          newj[i.to_s]['description'] += pio_stp_18(key['source_data'])
        when '19'
          newj[i.to_s]['description'] += pio_stp_19(key['source_data'])
        end # case end
      end # finished looping over step components
      newj[i.to_s]['tables'], table_str = protocolsio_string_to_table_element(
        newj[i.to_s]['description']
      )
      newj[i.to_s]['description'] = table_str
    end # steps
    newj
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

    render_403 unless can_view_team_protocols(@current_team)
  end

  def check_view_permissions
    @protocol = Protocol.find_by_id(params[:id])
    if @protocol.blank? || !can_view_protocol(@protocol)
      respond_to { |f| f.json { render json: {}, status: :unauthorized } }
    end
  end

  def check_create_permissions
    load_team_and_type

    render_403 if !can_create_new_protocol(@current_team) || @type == :archive
  end

  def check_clone_permissions
    load_team_and_type
    @original = Protocol.find_by_id(params[:id])

    if @original.blank? ||
       !can_clone_protocol(@original) || @type == :archive
      render_403
    end
  end

  def check_edit_permissions
    load_team_and_type
    @protocol = Protocol.find_by_id(params[:id])

    render_403 unless can_edit_protocol(@protocol)
  end

  def check_unlink_permissions
    @protocol = Protocol.find_by_id(params[:id])

    render_403 if @protocol.blank? || !can_unlink_protocol(@protocol)
  end

  def check_revert_permissions
    @protocol = Protocol.find_by_id(params[:id])

    render_403 if @protocol.blank? || !can_revert_protocol(@protocol)
  end

  def check_update_parent_permissions
    @protocol = Protocol.find_by_id(params[:id])

    render_403 if @protocol.blank? || !can_update_parent_protocol(@protocol)
  end

  def check_update_from_parent_permissions
    @protocol = Protocol.find_by_id(params[:id])

    if @protocol.blank? || !can_update_protocol_from_parent(@protocol)
      render_403
    end
  end

  def check_load_from_repository_views_permissions
    @protocol = Protocol.find_by_id(params[:id])

    render_403 if @protocol.blank? || !can_view_protocol(@protocol)
  end

  def check_load_from_repository_permissions
    @protocol = Protocol.find_by_id(params[:id])
    @source = Protocol.find_by_id(params[:source_id])

    if @protocol.blank? || @source.blank? || !can_load_protocol_from_repository(@protocol, @source)
      render_403
    end
  end

  def check_load_from_file_permissions
    @protocol_json = params[:protocol]
    @protocol = Protocol.find_by_id(params[:id])
    @my_module = @protocol.my_module

    if @protocol_json.blank? ||
       @protocol.blank? ||
       @my_module.blank? ||
       !can_load_protocol_into_module(@my_module)
      render_403
    end
  end

  def check_copy_to_repository_permissions
    @protocol = Protocol.find_by_id(params[:id])
    @my_module = @protocol.my_module

    if @my_module.blank? || !can_copy_protocol_to_repository(@my_module)
      render_403
    end
  end

  def check_make_private_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_make_protocol_private(protocol)
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_publish_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_publish_protocol(protocol)
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_archive_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_archive_protocol(protocol)
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_restore_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_restore_protocol(protocol)
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_import_permissions
    @protocol_json = params[:protocol]
    @team = Team.find(params[:team_id])
    @type = params[:type] ? params[:type].to_sym : nil
    unless
      @protocol_json.present? &&
      @team.present? &&
      (@type == :public || @type == :private) &&
      can_import_protocols(@team)

      render_403
    end
  end

  def check_export_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    if @protocols.blank? || @protocols.any? { |p| !can_export_protocol(p) }
      render_403
    end
  end

  def copy_to_repository_params
    params.require(:protocol).permit(:name, :protocol_type)
  end

  def create_params
    params.require(:protocol).permit(:name)
  end

  def metadata_params
    params.require(:protocol).permit(:name, :authors, :description)
  end
end
