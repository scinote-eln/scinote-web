# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::UsersController', type: :request do
  before :all do
    @user1 = create(:user)
    @user2 = create(:user)
    @user3 = create(:user)
    @team1 = create(:team, created_by: @user1)
    @team2 = create(:team, created_by: @user2)
    @team3 = create(:team, created_by: @user3)
    @owner_role = UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
    create_user_assignment(@team1, @owner_role, @user1)
    create_user_assignment(@team1, @owner_role, @user2)
    create_user_assignment(@team2, @owner_role, @user2)
    create_user_assignment(@team3, @owner_role, @user3)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user1.id) }
  end

  describe 'GET users, #index' do
    it 'When valid request, requested users are members of the team' do
      hash_body = nil
      get api_v1_team_users_path(team_id: @team1.id), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      pp hash_body[:data]
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@team1.users, each_serializer: Api::V1::UserSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, non existing team' do
      hash_body = nil
      get api_v1_team_users_path(team_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET user, #show' do
    it 'When valid request, requested user is member of the same teams' do
      hash_body = nil
      get api_v1_user_path(id: @user2.id), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@user2, serializer: Api::V1::UserSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, requested user is not member of the same teams' do
      hash_body = nil
      get api_v1_user_path(id: @user3.id), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing user' do
      hash_body = nil
      get api_v1_user_path(id: -1), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end
  end
end
