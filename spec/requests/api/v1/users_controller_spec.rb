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
    create(:user_team, user: @user1, team: @team1, role: 2)
    create(:user_team, user: @user2, team: @team1, role: 2)
    create(:user_team, user: @user2, team: @team2, role: 2)
    create(:user_team, user: @user3, team: @team3, role: 2)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user1.id) }
  end

  describe 'GET user, #show' do
    it 'When valid request, requested user is member of the same teams' do
      hash_body = nil
      get api_v1_user_path(id: @user2.id), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@user2, serializer: Api::V1::UserSerializer)
          .as_json[:data]
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
