# frozen_string_literal: true

class ExternalProtocolsController < ApplicationController
  before_action :load_vars
  before_action :check_import_permissions, only: [:create]

  # GET list_external_protocol
  def index
    service_call = ProtocolImporters::SearchProtocolsService
                   .call(protocol_source: 'protocolsio/v3', query_params: index_params)

    if service_call.succeed?
      render json: {
        html: render_to_string(
          partial: 'protocol_importers/list_of_protocol_cards.html.erb',
          locals: { protocols: service_call.protocols_list }
        )
      }
    else
      render json: { errors: service_call.errors }, status: 400
    end
  end

  # GET show_external_protocol
  def show
    # TODO: this should be refactored, it's only for placeholding
    endpoint_name = Constants::PROTOCOLS_ENDPOINTS.dig(*show_params[:protocol_source]
                                                  .split('/').map(&:to_sym))
    api_client = "ProtocolImporters::#{endpoint_name}::ApiClient".constantize.new
    html_preview = api_client.protocol_html_preview(show_params[:protocol_id])

    render json: {
      protocol_source: show_params[:protocol_source],
      protocol_id: show_params[:protocol_id],
      html: html_preview
    } and return
  rescue StandardError => e
    render json: {
      errors: [show_protocol: e.message]
    }, status: 400
  end

  # GET build_online_sources_protocol
  def new
    service_call = ProtocolImporters::BuildProtocolFromClientService.call(
      protocol_source: new_params[:protocol_source],
      protocol_client_id: new_params[:protocol_client_id],
      user_id: current_user.id,
      team_id: @team.id
    )

    if service_call.succeed?
      render json: {
        html: render_to_string(
          partial: 'protocol_importers/import_form.html.erb',
          locals: { protocol: service_call.built_protocol }
        )
      }
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

  def show_params
    params.permit(:protocol_source, :protocol_id)
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
