# frozen_string_literal: true

class MyModuleShareableLinksController < ApplicationController
  before_action :load_my_module, except: %i(my_module_protocol_show download_asset)
  before_action :load_shareable_link, only: %i(my_module_protocol_show download_asset)
  before_action :load_asset, only: :download_asset
  before_action :check_view_permissions, only: :show
  before_action :check_manage_permissions, except: %i(my_module_protocol_show download_asset)
  skip_before_action :authenticate_user!, only: %i(my_module_protocol_show download_asset)

  def show
    render json: @my_module.shareable_link, serializer: ShareableLinksSerializer
  end

  def my_module_protocol_show
    @my_module = @shareable_link.shareable
    render 'shareable_links/my_module_protocol_show', layout: 'shareable_links'
  end

  def download_asset
    redirect_to @asset.file.url(disposition: 'attachment')
  end

  def create
    @my_module.create_shareable_link(
      uuid: @my_module.signed_id(expires_in: 999.years),
      description: params[:description],
      team: @my_module.team,
      created_by: current_user
    )

    log_activity(:task_link_sharing_enabled)

    render json: @my_module.shareable_link, serializer: ShareableLinksSerializer
  end

  def update
    @my_module.shareable_link.update!(
      description: params[:description],
      last_modified_by: current_user
    )

    log_activity(:shared_task_message_edited)

    render json: @my_module.shareable_link, serializer: ShareableLinksSerializer
  end

  def destroy
    @my_module.shareable_link.destroy!

    log_activity(:task_link_sharing_disabled)

    render json: {}
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])
    render_404 unless @my_module
  end

  def load_shareable_link
    @shareable_link = ShareableLink.find_by(uuid: params[:uuid])

    return render_404 if @shareable_link.blank?

    @my_module = @shareable_link.shareable
  end

  def load_asset
    @asset = Asset.find_signed(params[:id])
    return render_404 if @asset.blank? || @my_module != @asset.step&.protocol&.my_module
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_share_my_module?(@my_module)
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: @my_module.team,
            project: @my_module.project,
            subject: @my_module,
            message_items: {
              my_module: @my_module.id,
              user: current_user.id
            })
  end
end
