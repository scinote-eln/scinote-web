class ExternalProtocolsController < ApplicationController
  before_action :load_vars
  before_action :check_import_permissions, only: [:create]

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
      team_id: @team.id
    )

    if service_call.succeed?
      render json: service_call.built_protocol
    else
      render json: { errors: service_call.errors }, status: 400
    end
  end

  # POST import_external_protocol
  def create
    service_call = ProtocolImporters::ImportProtocolService.call(
      protocol_params: create_params[:protocol_params],
      steps_params: create_params[:steps_paramas],
      user_id: current_user.id,
      team_id: @team.id
    )

    if service_call.succeed?
      render json: service_call.protocol
    else
      render json: { errors: service_call.errors }, status: 400
    end
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:team_id])

    render_404 unless @team
  end

  def index_params
    params.permit(:protocol_source, :key, :page_id, :page_size, :order_field, :order_dir)
  end

  def new_params
    params.permit(:protocol_source, :protocol_client_id)
  end

  def create_params
    params.permit(:protocol_params, :steps_params)
  end

  def check_import_permissions
    render_403 unless can_create_protocols_in_repository?(@team)
  end
end
