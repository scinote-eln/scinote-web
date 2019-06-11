class OnlineSourcesController < ApplicationController
  # GET
  def index
    # list_protocols = SearchService.call(index_params)
    succeed = false
    list_protocols = [
      { name: 'Protocol1' },
      { name: 'Protocol2' },
      { name: 'Protocol3' }
    ]

    if succeed
      render json: list_protocols
    else
      render json: {
        errors: { protocol: 'error_placeholder' }
      }, status: 400
    end
  end

  # GET
  def show

  end

  # GET team_build_online_sources_protocol
  def new
    service_call = ProtocolImporters::BuildProtocolFromClientService.call(
      protocol_source: new_params[:protocol_source],
      protocol_client_id: new_params[:protocol_client_id],
      user_id: current_user.id,
      team_id: current_team.id
    )

    if service_call.succeed?
      render json: service_call.built_protocol
    else
      render json: { errors: service_call.errors }, status: 400
    end
  end

  def create
  end

  private

  def index_params
    params.permit(:protocol_source, :key, :page_id, :page_size, :order_field, :order_dir)
  end

  def new_params
    params.permit(:protocol_source, :protocol_client_id)
  end
end
