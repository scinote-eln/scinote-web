# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V2::ProjectTeamAssignmentsController", type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team = create(:team, created_by: @user)
    @another_team = create(:team, created_by: @another_user)
    @normal_user_role = create :normal_user_role
    create_user_assignment(@team, @normal_user_role, @another_user)
    @project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @another_project = create(:project, name: Faker::Name.unique.name, created_by: @another_user, team: @team)
    @owner_role = UserRole.find_predefined_owner_role
    create_team_assignment(@project, @normal_user_role, @team)
    @invalid_project = create(:project, name: Faker::Name.unique.name, created_by: @another_user, team: @another_team)

    @valid_headers = { Authorization: "Bearer #{generate_token(@user.id)}" }
    @valid_headers_another_user = { Authorization: "Bearer #{generate_token(@another_user.id)}" }
  end

  describe 'GET #index' do
    it 'Response with correct team project assignments' do
      hash_body = nil
      get api_v2_team_project_team_assignments_path(team_id: @team.id, project_id: @project.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(ActiveModelSerializers::SerializableResource
          .new(@project.team_assignments, each_serializer: Api::V2::TeamAssignmentSerializer)
          .to_json)['data']
      )
    end

    it 'When invalid request, user is not an owner of the team and do not have access to project' do
      hash_body = nil
      get api_v2_team_project_team_assignments_path(team_id: @another_team.id, project_id: @invalid_project.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When valid request, user is an owner of the team and do not have access to project' do
      hash_body = nil
      get api_v2_team_project_team_assignments_path(team_id: @team.id, project_id: @another_project.id),
          headers: @valid_headers
      expect(response).to have_http_status(200)
      expect { hash_body = json }.not_to raise_exception
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v2_team_project_team_assignments_path(team_id: @team.id, project_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET #show' do
    it 'When valid request, user can read project users' do
      hash_body = nil
      get api_v2_team_project_team_assignment_path(
        team_id: @team.id, project_id: @project.id, id: @project.team_assignments.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(ActiveModelSerializers::SerializableResource
          .new(@project.team_assignments.first, serializer: Api::V2::TeamAssignmentSerializer)
          .to_json)['data']
      )
    end

    it 'When invalid request, user in not member of the project' do
      hash_body = nil
      get api_v2_team_project_team_assignment_path(
        team_id: @another_team.id, project_id: @invalid_project.id, id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v2_team_project_team_assignment_path(team_id: @team.id, project_id: -1, id: -1), headers: @valid_headers
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
      post(api_v2_team_project_team_assignments_path(team_id: @team.id, project_id: @another_project.id),
           params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'team_assignments',
            attributes: {
              user_role_id: @normal_user_role.id
            }
          }
        }
      end

      it 'returns well formated response' do
        expect { action }.to change { TeamAssignment.count }.by(1)
        expect(response).to have_http_status 201
        expect(json).to match(
          JSON.parse(ActiveModelSerializers::SerializableResource
            .new(@another_project.team_assignments.last, serializer: Api::V2::TeamAssignmentSerializer)
            .to_json)
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'team_assignments',
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
            type: 'team_assignments',
            attributes: {
              user_role_id: @normal_user_role.id
            }
          }
        }
      end

      it 'renders 403' do
        post(
          api_v2_team_project_team_assignments_path(
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

  describe 'PATCH #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @technician_user_role = create :technician_role
    end

    let(:action) do
      patch(
        api_v2_team_project_team_assignment_path(
          team_id: @project.team.id,
          project_id: @project.id,
          id: @project.team_assignments.last.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'team_assignments',
            attributes: {
              user_role_id: @technician_user_role.id
            }
          }
        }
      end

      it 'returns well formated response' do
        action
        expect(response).to have_http_status 200
        expect(json).to match(
          JSON.parse(ActiveModelSerializers::SerializableResource
            .new(Project.first.team_assignments.last, serializer: Api::V2::TeamAssignmentSerializer)
            .to_json)
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'team_assignments',
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
            type: 'team_assignments',
            attributes: {
              user_role_id: @technician_user_role.id
            }
          }
        }
      end

      it 'renders 403' do
        patch(
          api_v2_team_project_team_assignment_path(
            team_id: @invalid_project.team.id,
            project_id: @invalid_project.id,
            id: TeamAssignment.first.id
          ),
          params: request_body.to_json,
          headers: @valid_headers
        )

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE #delete' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      delete(
        api_v2_team_project_team_assignment_path(
          team_id: @project.team.id,
          project_id: @project.id,
          id: @project.team_assignments.last.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'user_group_assignments'
          }
        }
      end

      it 'returns well formated response' do
        action
        expect(response).to have_http_status(200)
        expect(@project.team_assignments.where(team_id: @team.id)).to_not exist
      end
    end
  end
end
