# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::ProjectUserAssignmentsController", type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @first_project_owner_user = create(:user)
    @team = create(:team, created_by: @user)
    @normal_user_role = create :normal_user_role
    create_user_assignment(@team, @normal_user_role, @another_user)
    create_user_assignment(@team, @normal_user_role, @first_project_owner_user)
    @own_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @owner_role = UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
    create_user_assignment(@own_project, @owner_role, @first_project_owner_user)
    @invalid_project =
      create(:project, name: Faker::Name.unique.name, created_by: @another_user, team: @team, visibility: :hidden)

    @valid_headers = { Authorization: "Bearer #{generate_token(@user.id)}" }
    @valid_headers_first_project_owner_user = {
      Authorization: "Bearer #{generate_token(@first_project_owner_user.id)}"
    }
  end

  describe 'GET #index' do
    it 'Response with correct user project assignments' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: @own_project.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(ActiveModelSerializers::SerializableResource
          .new(@own_project.user_assignments, each_serializer: Api::V1::UserAssignmentSerializer)
          .to_json)['data']
      )
    end

    it 'When invalid request, user is not an owner of the team and do not have access to project' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: @invalid_project.id),
          headers: @valid_headers_first_project_owner_user
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, user is an owner of the team and do not have access to project' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: @invalid_project.id),
          headers: @valid_headers
      expect(response).to have_http_status(200)
      expect { hash_body = json }.not_to raise_exception
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET #show' do
    it 'When valid request, user can read project users' do
      hash_body = nil
      get api_v1_team_project_user_path(
        team_id: @team.id, project_id: @own_project.id, id: @own_project.user_assignments.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(ActiveModelSerializers::SerializableResource
          .new(@own_project.user_assignments.first, serializer: Api::V1::UserAssignmentSerializer)
          .to_json)['data']
      )
    end

    it 'When invalid request, user in not member of the project' do
      hash_body = nil
      get api_v1_team_project_user_path(
        team_id: @team.id, project_id: @invalid_project.id, id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_user_path(team_id: @team.id, project_id: -1, id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST #create' do
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
            type: 'user_assignments',
            attributes: {
              user_id: @another_user.id,
              user_role_id: @normal_user_role.id
            }
          }
        }
      end

      it 'creates new user assignment' do
        expect { action }.to change { UserAssignment.count }.by(1)
      end

      it 'returns status 201' do
        action

        expect(response).to have_http_status 201
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          JSON.parse(ActiveModelSerializers::SerializableResource
            .new(Project.first.user_assignments.last, serializer: Api::V1::UserAssignmentSerializer)
            .to_json)
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'user_assignments',
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
            type: 'user_assignments',
            attributes: {
              user_id: @another_user.id,
              user_role_id: @normal_user_role.id
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
          headers: @valid_headers_first_project_owner_user
        )

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'PATCH #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @technician_user_role = create :technician_role
    end

    let(:action) do
      patch(
        api_v1_team_project_user_path(
          team_id: @own_project.team.id,
          project_id: @own_project.id,
          id: @own_project.user_assignments.last.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'user_assignments',
            attributes: {
              user_role_id: @technician_user_role.id
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
          JSON.parse(ActiveModelSerializers::SerializableResource
            .new(Project.first.user_assignments.last, serializer: Api::V1::UserAssignmentSerializer)
            .to_json)
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'project_user_assignments',
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
            type: 'project_user_assignments',
            attributes: {
              role: :technician
            }
          }
        }
      end

      it 'renders 404' do
        patch(
          api_v1_team_project_user_path(
            team_id: @invalid_project.team.id,
            project_id: @invalid_project.id,
            id: UserAssignment.first.id
          ),
          params: request_body.to_json,
          headers: @valid_headers
        )

        expect(response).to have_http_status(404)
      end
    end
  end
end
