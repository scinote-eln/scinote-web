class ProtocolsController < ApplicationController
  include RenamingUtil
  include ProtocolsImporter
  include ProtocolsExporter

  before_action :check_create_permissions, only: [
    :create_new_modal,
    :create
  ]
  before_action :check_clone_permissions, only: [ :clone ]
  before_action :check_view_permissions, only: [
    :protocol_status_bar,
    :updated_at_label,
    :linked_children,
    :linked_children_datatable
  ]
  before_action :check_edit_permissions, only: [
    :edit,
    :update_metadata,
    :update_keywords,
    :edit_name_modal,
    :edit_keywords_modal,
    :edit_authors_modal,
    :edit_description_modal
  ]
  before_action :check_view_all_permissions, only: [
    :index,
    :datatable
  ]
  before_action :check_unlink_permissions, only: [
    :unlink,
    :unlink_modal
  ]
  before_action :check_revert_permissions, only: [
    :revert,
    :revert_modal
  ]
  before_action :check_update_parent_permissions, only: [
    :update_parent,
    :update_parent_modal
  ]
  before_action :check_update_from_parent_permissions, only: [
    :update_from_parent,
    :update_from_parent_modal
  ]
  before_action :check_load_from_repository_views_permissions, only: [
    :load_from_repository_modal,
    :load_from_repository_datatable
  ]
  before_action :check_load_from_repository_permissions, only: [
    :load_from_repository
  ]
  before_action :check_load_from_file_permissions, only: [
    :load_from_file
  ]
  before_action :check_copy_to_repository_permissions, only: [
    :copy_to_repository,
    :copy_to_repository_modal
  ]
  before_action :check_make_private_permissions, only: [ :make_private ]
  before_action :check_publish_permissions, only: [ :publish ]
  before_action :check_archive_permissions, only: [ :archive ]
  before_action :check_restore_permissions, only: [ :restore ]
  before_action :check_import_permissions, only: [ :import ]
  before_action :check_export_permissions, only: [ :export ]

  def index
  end

  def update_comment
    id = request.request_parameters[:id]
    msg = request.request_parameters[:msg]

    Comment.where(id:id).update_all(message:msg)

    rb_json = JSON.parse('{"json":['+id+']}') 
    respond_to do |format|      
        format.json {render json: rb_json["json"]}
      end
  end

  def delete_comment
    id = request.request_parameters[:id]


    StepComment.where(comment_id:id).destroy_all
    Comment.find(id).destroy

    rb_json = JSON.parse('{"json":['+id+']}') 
    respond_to do |format|      
        format.json {render json: rb_json["json"]}
      end
  end

  def datatable
    respond_to do |format|
      format.json {
        render json: ::ProtocolsDatatable.new(
          view_context,
          @current_organization,
          @type,
          current_user
        )
      }
    end
  end

  def linked_children
    respond_to do |format|
      format.json {
        render json: {
          title: I18n.t("protocols.index.linked_children.title", protocol: @protocol.name),
          html: render_to_string({
            partial: "protocols/index/linked_children_modal_body.html.erb",
            locals: { protocol: @protocol }
          })
        }
      }
    end
  end

  def linked_children_datatable
    respond_to do |format|
      format.json {
        render json: ::ProtocolLinkedChildrenDatatable.new(
          view_context,
          @protocol,
          current_user,
          self
        )
      }
    end
  end

  def make_private
    move_protocol("make_private")
  end

  def publish
    move_protocol("publish")
  end

  def archive
    move_protocol("archive")
  end

  def restore
    move_protocol("restore")
  end

  def edit
  end

  def update_metadata
    @protocol.record_timestamps = false
    @protocol.assign_attributes(metadata_params)

    respond_to do |format|
      if @protocol.save
        format.json {
          render json: {
            updated_at_label: render_to_string(
              partial: "protocols/header/updated_at_label.html.erb"
            ),
            name_label: render_to_string(
              partial: "protocols/header/name_label.html.erb"
            ),
            authors_label: render_to_string(
              partial: "protocols/header/authors_label.html.erb"
            ),
            description_label: render_to_string(
              partial: "protocols/header/description_label.html.erb"
            )
          }
        }
      else
        format.json {
          render json: @protocol.errors,
            status: :unprocessable_entity
        }
      end
    end
  end

  def update_keywords
    respond_to do |format|
      if @protocol.update_keywords(params[:keywords])
        format.json {
          render json: {
            updated_at_label: render_to_string(
              partial: "protocols/header/updated_at_label.html.erb"
            ),
            keywords_label: render_to_string(
              partial: "protocols/header/keywords_label.html.erb"
            )
          }
        }
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def create
    @protocol = Protocol.new(
      organization: @current_organization,
      protocol_type: Protocol.protocol_types[@type == :public ? :in_repository_public : :in_repository_private],
      added_by: current_user
    )
    @protocol.assign_attributes(create_params)

    ts = Time.now
    @protocol.record_timestamps = false
    @protocol.created_at = ts
    @protocol.updated_at = ts
    if @type == :public
      @protocol.published_on = ts
    end

    respond_to do |format|
      if @protocol.save
        format.json {
          render json: {
            url: edit_protocol_path(
              @protocol,
              organization: @current_organization,
              type: @type
            )
          }
        }
      else
        format.json {
          render json: @protocol.errors,
            status: :unprocessable_entity
        }
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
      if cloned != nil
        flash[:success] = t(
          "protocols.index.clone.success_flash",
          original: @original.name,
          new: cloned.name
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      else
        flash[:error] = t(
          "protocols.index.clone.error_flash",
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
        format.json {
          render json: {
            message: t("my_modules.protocols.copy_to_repository_modal.error_400")
          },
          status: :bad_request
        }
      elsif @new.invalid?
        # Render errors
        format.json {
          render json: @new.errors,
          status: :unprocessable_entity
        }
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
        format.json {
          render json: {
            message: t("my_modules.protocols.unlink_error")
          },
          status: :bad_request
        }
      else
        # Everything good, display flash & render 200
        flash[:success] = t(
          "my_modules.protocols.unlink_flash",
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def revert
    respond_to do |format|
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
        format.json {
          render json: {
            message: t("my_modules.protocols.revert_error")
          },
          status: :bad_request
        }
      else
        # Everything good, display flash & render 200
        flash[:success] = t(
          "my_modules.protocols.revert_flash",
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def update_parent
    respond_to do |format|
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
        format.json {
          render json: {
            message: t("my_modules.protocols.update_parent_error")
          },
          status: :bad_request
        }
      else
        # Everything good, display flash & render 200
        flash[:success] = t(
          "my_modules.protocols.update_parent_flash",
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def update_from_parent
    respond_to do |format|
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
        format.json {
          render json: {
            message: t("my_modules.protocols.update_from_parent_error")
          },
          status: :bad_request
        }
      else
        # Everything good, display flash & render 200
        flash[:success] = t(
          "my_modules.protocols.update_from_parent_flash",
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def load_from_repository
    respond_to do |format|
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
        format.json {
          render json: {
            message: t("my_modules.protocols.load_from_repository_error")
          },
          status: :bad_request
        }
      else
        # Everything good, display flash & render 200
        flash[:success] = t(
          "my_modules.protocols.load_from_repository_flash",
        )
        flash.keep(:success)
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def load_from_file
    # This is actually very similar to import
    respond_to do |format|
      transaction_error = false
      Protocol.transaction do
        begin
          import_into_existing(@protocol, @protocol_json, current_user)
        rescue Exception
          transaction_error = true
          raise ActiveRecord:: Rollback
        end
      end

      if transaction_error
        format.json {
          render json: { status: :error }, status: :bad_request
        }
      else
        # Everything good, display flash & render 200
        flash[:success] = t(
          "my_modules.protocols.load_from_file_flash",
        )
        flash.keep(:success)
        format.json {
          render json: { status: :ok }, status: :ok
        }
      end
    end
  end

  def import
    protocol = nil
    respond_to do |format|
      transaction_error = false
      Protocol.transaction do
        begin
          protocol = import_new_protocol(@protocol_json, @organization, @type, current_user)
        rescue Exception
          transaction_error = true
          raise ActiveRecord:: Rollback
        end
      end

      p_name = (
        @protocol_json["name"].present? &&
        !@protocol_json["name"].empty?
      ) ? @protocol_json["name"] : t("protocols.index.no_protocol_name")
      if transaction_error
        format.json {
          render json: { name: p_name, status: :bad_request }, status: :bad_request
        }
      else
        format.json {
          render json: {
            name: p_name, new_name: protocol.name, status: :ok
          },
          status: :ok
        }
      end
    end
  end

  def export
    respond_to do |format|
      format.json {
        render json: {
            protocols: export_protocols(@protocols)
          }, status: :ok
      }
    end
  end

  def unlink_modal
    respond_to do |format|
      format.json {
        render json: {
          title: t("my_modules.protocols.confirm_link_update_modal.unlink_title"),
          message: t("my_modules.protocols.confirm_link_update_modal.unlink_message"),
          btn_text: t("my_modules.protocols.confirm_link_update_modal.unlink_btn_text"),
          url: unlink_protocol_path(@protocol)
        }
      }
    end
  end

  def revert_modal
    respond_to do |format|
      format.json {
        render json: {
          title: t("my_modules.protocols.confirm_link_update_modal.revert_title"),
          message: t("my_modules.protocols.confirm_link_update_modal.revert_message"),
          btn_text: t("my_modules.protocols.confirm_link_update_modal.revert_btn_text"),
          url: revert_protocol_path(@protocol)
        }
      }
    end
  end

  def update_parent_modal
    respond_to do |format|
      format.json {
        render json: {
          title: t("my_modules.protocols.confirm_link_update_modal.update_parent_title"),
          message: t("my_modules.protocols.confirm_link_update_modal.update_parent_message"),
          btn_text: t("general.update"),
          url: update_parent_protocol_path(@protocol)
        }
      }
    end
  end

  def update_from_parent_modal
    respond_to do |format|
      format.json {
        render json: {
          title: t("my_modules.protocols.confirm_link_update_modal.update_self_title"),
          message: t("my_modules.protocols.confirm_link_update_modal.update_self_message"),
          btn_text: t("general.update"),
          url: update_from_parent_protocol_path(@protocol)
        }
      }
    end
  end

  def load_from_repository_datatable
    @protocol = Protocol.find_by_id(params[:id])
    @type = (params[:type] || "public").to_sym
    respond_to do |format|
      format.json {
        render json: ::LoadFromRepositoryProtocolsDatatable.new(
          view_context,
          @protocol.organization,
          @type,
          current_user
        )
      }
    end
  end

  def load_from_repository_modal
    @protocol = Protocol.find_by_id(params[:id])
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "my_modules/protocols/load_from_repository_modal_body.html.erb"
          })
        }
      }
    end
  end

  def copy_to_repository_modal
    @new = Protocol.new
    @original = Protocol.find(params[:id])
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "my_modules/protocols/copy_to_repository_modal_body.html.erb"
          })
        }
      }
    end
  end

  def protocol_status_bar
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "my_modules/protocols/protocol_status_bar.html.erb"
          })
        }
      }
    end
  end

  def updated_at_label
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "protocols/header/updated_at_label.html.erb"
          })
        }
      }
    end
  end

  def create_new_modal
    @new_protocol = Protocol.new
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "protocols/index/create_new_modal_body.html.erb"
          })
        }
      }
    end
  end

  def edit_name_modal
    respond_to do |format|
      format.json {
        render json: {
          title: I18n.t("protocols.header.edit_name_modal.title", protocol: @protocol.name),
          html: render_to_string({
            partial: "protocols/header/edit_name_modal_body.html.erb"
          })
        }
      }
    end
  end

  def edit_keywords_modal
    respond_to do |format|
      format.json {
        render json: {
          title: I18n.t("protocols.header.edit_keywords_modal.title", protocol: @protocol.name),
          html: render_to_string({
            partial: "protocols/header/edit_keywords_modal_body.html.erb"
          }),
          keywords: @protocol.organization.protocol_keywords_list
        }
      }
    end
  end

  def edit_authors_modal
    respond_to do |format|
      format.json {
        render json: {
          title: I18n.t("protocols.header.edit_authors_modal.title", protocol: @protocol.name),
          html: render_to_string({
            partial: "protocols/header/edit_authors_modal_body.html.erb"
          })
        }
      }
    end
  end

  def edit_description_modal
    respond_to do |format|
      format.json {
        render json: {
          title: I18n.t("protocols.header.edit_description_modal.title", protocol: @protocol.name),
          html: render_to_string({
            partial: "protocols/header/edit_description_modal_body.html.erb"
          })
        }
      }
    end
  end

  private

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
      unless rollbacked
        format.json {
          render json: {
            html: render_to_string({
              partial: "protocols/index/results_modal_body.html.erb",
              locals: { results: results, en_action: "#{action}_results" }
            })
          }
        }
      else
        format.json {
          render json: {}, status: :bad_request
        }
      end
    end
  end

  def load_organization_and_type
    @organizations = current_user.organizations.order(name: :asc)
    @current_organization = @organizations.select{ |org| org.id == params[:organization].to_i }.first
    @current_organization ||= @organizations.first
    # :public, :private or :archive
    @type = (params[:type] || "public").to_sym
  end

  def check_view_all_permissions
    load_organization_and_type

    unless can_view_organization_protocols(@current_organization)
      render_403
    end
  end

  def check_view_permissions
    @protocol = Protocol.find_by_id(params[:id])
    if @protocol.blank? || !can_view_protocol(@protocol)
      respond_to { |f| f.json { render json: {}, status: :unauthorized } }
    end
  end

  def check_create_permissions
    load_organization_and_type

    if !can_create_new_protocol(@current_organization) || @type == :archive
      render_403
    end
  end

  def check_clone_permissions
    load_organization_and_type
    @original = Protocol.find_by_id(params[:id])

    if @original.blank? ||
      !can_clone_protocol(@original) || @type == :archive
      render_403
    end
  end

  def check_edit_permissions
    load_organization_and_type
    @protocol = Protocol.find_by_id(params[:id])

    unless can_edit_protocol(@protocol)
      render_403
    end
  end

  def check_unlink_permissions
    @protocol = Protocol.find_by_id(params[:id])

    if @protocol.blank? || !can_unlink_protocol(@protocol)
      render_403
    end
  end

  def check_revert_permissions
    @protocol = Protocol.find_by_id(params[:id])

    if @protocol.blank? || !can_revert_protocol(@protocol)
      render_403
    end
  end

  def check_update_parent_permissions
    @protocol = Protocol.find_by_id(params[:id])

    if @protocol.blank? || !can_update_parent_protocol(@protocol)
      render_403
    end
  end

  def check_update_from_parent_permissions
    @protocol = Protocol.find_by_id(params[:id])

    if @protocol.blank? || !can_update_protocol_from_parent(@protocol)
      render_403
    end
  end

  def check_load_from_repository_views_permissions
    @protocol = Protocol.find_by_id(params[:id])

    if @protocol.blank? || !can_view_protocol(@protocol)
      render_403
    end
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

    if @my_module.blank? or !can_copy_protocol_to_repository(@my_module)
      render_403
    end
  end

  def check_make_private_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_make_protocol_private(protocol) then
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_publish_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_publish_protocol(protocol) then
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_archive_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_archive_protocol(protocol) then
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_restore_permissions
    @protocols = Protocol.where(id: params[:protocol_ids])
    @protocols.find_each do |protocol|
      unless can_restore_protocol(protocol) then
        respond_to { |f| f.json { render json: {}, status: :unauthorized } }
        return
      end
    end
  end

  def check_import_permissions
    @protocol_json = params[:protocol]
    @organization = Organization.find(params[:organization_id])
    @type = params[:type] ? params[:type].to_sym : nil
    if !(
      @protocol_json.present? &&
      @organization.present? &&
      (@type == :public || @type == :private) &&
      can_import_protocols(@organization)
    )
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
