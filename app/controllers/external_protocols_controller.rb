# frozen_string_literal: true

class ExternalProtocolsController < ApplicationController
  before_action :load_vars
  before_action :check_import_permissions, only: [:create]

  # GET list_external_protocols
  def index
    service_call = ProtocolImporters::SearchProtocolsService
                   .call(protocol_source: index_params[:protocol_source],
                         query_params: index_params)
    if service_call.succeed?
      show_import_button = can_create_protocols_in_repository?(@team)
      render json: {
        html: render_to_string(
          partial: 'protocol_importers/list_of_protocol_cards',
          locals: { protocols: service_call.protocols_list, show_import_button: show_import_button }
        ),
        page_id: service_call.protocols_list[:pagination][:current_page]
      }
    else
      render json: { errors: service_call.errors }, status: :bad_request
    end
  end

  # GET show_external_protocol
  def show
    # TODO: this should be refactored, it's only for placeholding
    endpoint_name = Constants::PROTOCOLS_ENDPOINTS.dig(*show_params[:protocol_source]
                                                  .split('/').map(&:to_sym))
    api_client = "ProtocolImporters::#{endpoint_name}::ApiClient".constantize.new

    html_preview_request = api_client.protocol_html_preview(show_params[:protocol_id])
    base_uri = URI.parse(html_preview_request.request.last_uri.to_s)
    base_uri = "#{base_uri.scheme}://#{base_uri.host}"

    render json: {
      protocol_source: show_params[:protocol_source],
      protocol_id: show_params[:protocol_id],
      base_uri: base_uri,
      html: html_preview_request.body
    }
  rescue StandardError => e
    render json: {
      errors: [protocol_html_preview: e.message]
    }, status: :bad_request
  end

  # GET build_online_sources_protocol
  def new
    service_call = ProtocolImporters::BuildProtocolFromClientService.call(
      protocol_source: new_params[:protocol_source],
      protocol_client_id: new_params[:protocol_client_id],
      user_id: current_user.id,
      team_id: @team.id,
      build_with_assets: false
    )

    if service_call.succeed?
      @protocol = service_call.built_protocol
      @protocol&.valid? # Get validations errors here

      render json: {
        html: render_to_string(
          partial: 'protocol_importers/import_form',
          locals: { protocol: @protocol,
                    steps_json: service_call.serialized_steps,
                    steps_assets: service_call.steps_assets }
        ),
        title: t('protocol_importers.new.modal_title', protocol_name: @protocol.name),
        footer: render_to_string(
          partial: 'protocol_importers/preview_modal_footer'
        ),
        validation_errors: { protocol: @protocol.errors.messages }
      }
    else
      render json: { errors: service_call.errors }, status: :bad_request
    end
  end

  # POST import_external_protocol
  def create
    service_call = ProtocolImporters::ImportProtocolService.call(
      protocol_params: create_protocol_params,
      steps_params_json: create_steps_params[:steps],
      user: current_user,
      team: @team
    )

    if service_call.succeed?
      message = t('protocols.index.protocolsio.import.success_flash', name: service_call.protocol.name)
      render json: { protocol: service_call.protocol, message: message }
    else
      render json: { validation_errors: service_call.errors }, status: :bad_request
    end
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:team_id])

    render_404 unless @team
  end

  def index_params
    params.permit(:team_id, :protocol_source, :key, :page_id, :page_size, :sort_by)
  end

  def show_params
    params.permit(:team_id, :protocol_source, :protocol_id)
  end

  def new_params
    params.permit(:team_id, :protocol_source, :protocol_client_id)
  end

  def create_protocol_params
    params
      .require(:protocol)
      .permit(:name, :authors, :published_on, :protocol_type, :description, :visibility, :default_public_user_role_id)
      .except(:steps)
  end

  def create_steps_params
    params.require(:protocol).permit(:steps)
  end

  def check_import_permissions
    render_403 unless can_create_protocols_in_repository?(@team)
  end
end
