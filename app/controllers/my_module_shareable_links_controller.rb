# frozen_string_literal: true

class MyModuleShareableLinksController < ApplicationController
  before_action :load_my_module, except: %i(my_module_protocol_show)
  before_action :load_shareable_link, only: %i(update destroy)
  before_action :check_view_permissions, only: :show
  before_action :check_manage_permissions, except: %i(show my_module_protocol_show)
  skip_before_action :authenticate_user!, only: %(my_module_protocol_show)

  def show
    render json: @my_module.shareable_link
  end

  def my_module_protocol_show
    shareable_link = ShareableLink.find_by(uuid: params[:uuid])

    return render_403 if shareable_link.blank?

    @my_module = shareable_link.shareable
    render 'shareable_links/my_module_protocol_show', layout: 'shareable_links'
  end

  def create
    @my_module.create_shareable_link(
      uuid: @my_module.signed_id,
      description: params[:description],
      team: @my_module.team,
      created_by: current_user
    )

    render json: @my_module.shareable_link
  end

  def update
    @my_module.shareable_link.update!(
      description: params[:description],
      last_modified_by: current_user
    )

    render json: @my_module.shareable_link
  end

  def destroy
    @my_module.shareable_link.destroy!

    render json: {}
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])
    render_404 unless @my_module
  end

  def check_view_permissions
    render_403 unless can_view_my_module?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_share_my_module?(@my_module)
  end
end
