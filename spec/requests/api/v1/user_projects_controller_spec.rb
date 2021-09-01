# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::UserProjectsController", type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team = create(:team, created_by: @user)
    create(:user_team, user: @user, team: @team, role: :normal_user)
    create(:user_team, user: @another_user, team: @team, role: :normal_user)
    @own_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @invalid_project =
      create(:project, name: Faker::Name.unique.name, created_by: @another_user, team: @team, visibility: :hidden)
    create(:user_project, role: :owner, user: @user, project: @own_project)

    @valid_headers = { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET user_projects, #index' do
    it 'Response with correct user project roles' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: @own_project.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@own_project.user_projects, each_serializer: Api::V1::UserProjectSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not an owner of the project' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: @invalid_project.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET user_project, #show' do
    it 'When valid request, user can read project users' do
      hash_body = nil
      get api_v1_team_project_user_path(
        team_id: @team.id, project_id: @own_project.id, id: @own_project.user_projects.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@own_project.user_projects.first, serializer: Api::V1::UserProjectSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the project' do
      hash_body = nil
      get api_v1_team_project_user_path(
        team_id: @team.id, project_id: @invalid_project.id, id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_user_path(team_id: @team.id, project_id: -1, id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST user_project, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      post(api_v1_team_project_users_path(team_id: @team.id, project_id: @own_project.id),
           params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'user_projects',
            attributes: {
              user_id: @another_user.id,
              role: 'normal_user'
            }
          }
        }
      end

      it 'creates new user_project' do
        expect { action }.to change { UserProject.count }.by(1)
      end

      it 'returns status 201' do
        action

        expect(response).to have_http_status 201
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'user_projects',
              attributes: hash_including(role: 'normal_user'),
              relationships: hash_including(user: hash_including(data: hash_including(id: @another_user.id.to_s)))
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'user_projects',
            attributes: {}
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end

    context 'when user is not an owner of the project' do
      let(:request_body) do
        {
          data: {
            type: 'user_projects',
            attributes: {
              user_id: @another_user.id,
              role: 'normal_user'
            }
          }
        }
      end

      it 'renders 403' do
        post(
          api_v1_team_project_users_path(
            team_id: @invalid_project.team.id,
            project_id: @invalid_project.id
          ),
          params: request_body.to_json,
          headers: @valid_headers
        )

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'PATCH user_project, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @user_project = create(:user_project, role: :normal_user, user: @another_user, project: @own_project)
    end

    let(:action) do
      patch(
        api_v1_team_project_user_path(
          team_id: @own_project.team.id,
          project_id: @own_project.id,
          id: @user_project.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'user_projects',
            attributes: {
              role: :technician
            }
          }
        }
      end

      it 'returns status 200' do
        action

        expect(response).to have_http_status 200
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'user_projects',
              attributes: hash_including(role: 'technician')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'user_projects',
            attributes: {
            }
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end

    context 'when user is not an owner of the project' do
      let(:request_body) do
        {
          data: {
            type: 'user_projects',
            attributes: {
              role: :technician
            }
          }
        }
      end

      it 'renders 403' do
        user_project = create(:user_project, role: :normal_user, user: @another_user, project: @invalid_project)
        patch(
          api_v1_team_project_user_path(
            team_id: @invalid_project.team.id,
            project_id: @invalid_project.id,
            id: user_project.id
          ),
          params: request_body.to_json,
          headers: @valid_headers
        )

        expect(response).to have_http_status(403)
      end
    end
  end
end
