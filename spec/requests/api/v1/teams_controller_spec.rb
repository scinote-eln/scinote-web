# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TeamsController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 3, created_by: @user)
    @owner_role = UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET teams, #index' do
    it 'Response with correct teams' do
      hash_body = nil
      get api_v1_teams_path, headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@user.teams, each_serializer: Api::V1::TeamSerializer)
            .to_json
        )['data']
      )
    end
  end

  describe 'GET team, #show' do
    it 'When valid request, user is member of the team' do
      hash_body = nil
      get api_v1_team_path(id: @teams.second.id), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@teams.second, serializer: Api::V1::TeamSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      @teams.first.user_assignments.delete_all
      get api_v1_team_path(id: @teams.first.id), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing team' do
      hash_body = nil
      get api_v1_team_path(id: 123), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end
end
