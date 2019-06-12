# frozen_string_literal: true

require 'rails_helper'

describe ExternalProtocolsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }

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

    it 'returns JSON, 200 response when protocol parsing was valid' do
      # Setup double
      service = double('success_service')
      allow(service).to(receive(:succeed?)).and_return(true)
      allow(service).to(receive(:built_protocol)).and_return({})

      allow_any_instance_of(ProtocolImporters::BuildProtocolFromClientService).to(receive(:call)).and_return(service)

      # Call action
      action
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq 'application/json'
    end

    it 'returns JSON, 400 response when protocol parsing was invalid' do
      # Setup double
      service = double('success_service')
      allow(service).to(receive(:succeed?)).and_return(false)
      allow(service).to(receive(:errors)).and_return({})

      allow_any_instance_of(ProtocolImporters::BuildProtocolFromClientService).to(receive(:call)).and_return(service)

      # Call action
      action
      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to eq 'application/json'
    end

  end

  describe 'POST create' do
    context 'when user has import permissions for the team' do
      let(:params) do
        {
          team_id: team.id,
          protocol_params: {},
          steps_params: {}
        }
      end

      let(:action) { post :create, params: params }

      it 'returns JSON, 200 response when protocol parsing was valid' do
        # Setup double
        service = double('success_service')
        allow(service).to(receive(:succeed?)).and_return(true)
        allow(service).to(receive(:protocol)).and_return({})

        allow_any_instance_of(ProtocolImporters::ImportProtocolService).to(receive(:call)).and_return(service)

        # Call action
        action
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq 'application/json'
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
        expect(response.content_type).to eq 'application/json'
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
