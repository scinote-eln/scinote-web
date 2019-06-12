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
end
