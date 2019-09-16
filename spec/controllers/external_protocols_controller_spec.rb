# frozen_string_literal: true

require 'rails_helper'

describe ExternalProtocolsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }

  describe 'GET index' do
    let(:params) do
      {
        team_id: team.id,
        key: 'search_string',
        protocol_source: 'protocolsio/v3',
        page_id: 2,
        page_size: 50,
        order_field: 'activity',
        order_dir: 'desc'
      }
    end

    let(:action) { get :index, params: params }

    let(:valid_search_response) do
      {
        protocols: [],
        pagination: {
          current_page: 2,
          total_pages: 6,
          page_size: 10
        }
      }
    end

    before do
      service = double('success_service')
      allow(service).to(receive(:succeed?)).and_return(true)
      allow(service).to(receive(:protocols_list)).and_return(valid_search_response)

      allow_any_instance_of(ProtocolImporters::SearchProtocolsService).to(receive(:call)).and_return(service)
    end

    it 'returns JSON, 200 response when protocol parsing was valid' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end

    it 'contains html key in the response' do
      action
      expect(JSON.parse(response.body)).to have_key('html')
    end

    it 'contains page_id in the response' do
      action
      expect(JSON.parse(response.body)['page_id']).to eq 2
    end
  end

  describe 'GET show' do
    let(:params) do
      {
        team_id: team.id,
        protocol_source: 'protocolsio/v3',
        protocol_id: 'protocolsio_uri'
      }
    end

    let(:action) { get :show, params: params }

    let(:html_preview) { double('html_preview') }

    before do
      allow(html_preview).to(receive(:as_json).and_return('<html></html>'))
      allow(html_preview).to(receive_message_chain(:request, :last_uri, :to_s).and_return('http://www.protocols.io/test_protocol'))
    end

    it 'returns JSON, 200 response when preview was successfully returned' do
      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:protocol_html_preview)).and_return(html_preview)

      # Call action
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end

    it 'should return html preview in the JSON' do
      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:protocol_html_preview)).and_return(html_preview)

      # Call action
      action
      expect(JSON.parse(response.body)['html']).to eq('<html></html>')
    end

    it 'returns error JSON and 400 response when something went wrong' do
      allow_any_instance_of(ProtocolImporters::ProtocolsIo::V3::ApiClient)
        .to(receive(:protocol_html_preview)).and_raise(StandardError)

      # Call action
      action
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to have_key('errors')
    end
  end

  describe 'GET new' do
    let(:params) do
      {
        team_id: team.id,
        protocol_source: 'protocolsio/v3',
        page_id: 1,
        page_size: 10,
        order_field: 'activity',
        order_dir: 'desc'
      }
    end

    let(:action) { get :new, params: params }

    context 'successful response' do
      let(:protocol) { create :protocol }

      before do
        service = double('success_service')
        allow(service).to(receive(:succeed?)).and_return(true)
        allow(service).to(receive(:built_protocol)).and_return(protocol)
        allow(service).to(receive(:serialized_steps)).and_return({}.to_s)
        allow(service).to(receive(:steps_assets)).and_return([])

        allow_any_instance_of(ProtocolImporters::BuildProtocolFromClientService)
          .to(receive(:call)).and_return(service)
      end

      it 'returns JSON, 200 response when protocol parsing was valid' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'should return html form in the JSON' do
        action
        expect(JSON.parse(response.body)).to have_key('html')
      end
    end

    it 'returns JSON, 400 response when protocol parsing was invalid' do
      # Setup double
      service = double('failed_service')
      allow(service).to(receive(:succeed?)).and_return(false)
      allow(service).to(receive(:errors)).and_return({})

      allow_any_instance_of(ProtocolImporters::BuildProtocolFromClientService)
        .to(receive(:call)).and_return(service)

      # Call action
      action
      expect(response).to have_http_status(:bad_request)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe 'POST create' do
    context 'when user has import permissions for the team' do
      let(:params) do
        {
          team_id: team.id,
          protocol: {
            name: 'name',
            steps: {}.to_s
          }
        }
      end

      let(:action) { post :create, params: params }

      it 'returns JSON, 200 response when protocol parsing was valid' do
        # Setup double
        service = double('success_service')
        allow(service).to(receive(:succeed?)).and_return(true)
        allow(service).to(receive(:protocol)).and_return(create(:protocol))

        allow_any_instance_of(ProtocolImporters::ImportProtocolService).to(receive(:call)).and_return(service)

        # Call action
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'returns JSON, 400 response when protocol parsing was invalid' do
        # Setup double
        service = double('success_service')
        allow(service).to(receive(:succeed?)).and_return(false)
        allow(service).to(receive(:errors)).and_return({})

        allow_any_instance_of(ProtocolImporters::ImportProtocolService).to(receive(:call)).and_return(service)

        # Call action
        action
        expect(response).to have_http_status(:bad_request)
        expect(response.media_type).to eq 'application/json'
      end
    end

    context 'when user has no import permissions for the team' do
      let(:user_two) { create :user }
      let(:team_two) { create :team, created_by: user_two }

      let(:params) do
        {
          team_id: team_two.id,
          protocol_params: {},
          steps_params: {}
        }
      end

      it 'returns 403 when trying to import to forbidden team' do
        post :create, params: params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
