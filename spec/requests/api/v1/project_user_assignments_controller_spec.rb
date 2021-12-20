# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::ProjectUserAssignmentsController", type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team = create(:team, created_by: @user)
    create(:user_team, user: @user, team: @team, role: :normal_user)
    create(:user_team, user: @another_user, team: @team, role: :normal_user)
    @own_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @invalid_project =
      create(:project, name: Faker::Name.unique.name, created_by: @another_user, team: @team, visibility: :hidden)
    create(:user_project, user: @user, project: @own_project)
    create :user_assignment, assignable: @own_project, user: @user, user_role: UserRole.find_by(name: I18n.t('user_roles.predefined.owner')), assigned_by: @user
    @normal_user_role = create :normal_user_role

    @valid_headers = { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET #index' do
    it 'Response with correct user project assignments' do
      hash_body = nil
      get api_v1_team_project_users_path(team_id: @team.id, project_id: @own_project.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@own_project.user_assignments, each_serializer: Api::V1::ProjectUserAssignmentSerializer)
          .as_json[:data]
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

  describe 'GET #show' do
    it 'When valid request, user can read project users' do
      hash_body = nil
      get api_v1_team_project_user_path(
        team_id: @team.id, project_id: @own_project.id, id: @own_project.user_assignments.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@own_project.user_assignments.first, serializer: Api::V1::ProjectUserAssignmentSerializer)
          .as_json[:data]
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
            type: 'project_user_assignments',
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
          hash_including(
            data: hash_including(
              type: 'project_user_assignments',
              relationships: hash_including(
                user: hash_including(data: hash_including(id: @another_user.id.to_s)),
                user_role: hash_including(data: hash_including(id: @normal_user_role.id.to_s))
              )
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'project_user_assignments',
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
            type: 'project_user_assignments',
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
          headers: @valid_headers
        )

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'PATCH #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      create(:user_project, user: @another_user, project: @own_project)
      @user_assignment = create :user_assignment,
                                 assignable: @own_project,
                                 user: @another_user,
                                 user_role: @normal_user_role,
                                 assigned_by: @user
      @technician_user_role = create :technician_role
    end

    let(:action) do
      patch(
        api_v1_team_project_user_path(
          team_id: @own_project.team.id,
          project_id: @own_project.id,
          id: @user_assignment.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'project_user_assignments',
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
          hash_including(
            data: hash_including(
              type: 'project_user_assignments',
              relationships: hash_including(
                user: hash_including(data: hash_including(id: @another_user.id.to_s)),
                user_role: hash_including(data: hash_including(id: @technician_user_role.id.to_s))
              )
            )
          )
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

      it 'renders 403' do
        create(:user_project, user: @another_user, project: @invalid_project)
        user_assignment = create :user_assignment,
                                  assignable: @invalid_project,
                                  user: @another_user,
                                  user_role: @normal_user_role,
                                  assigned_by: @user

        patch(
          api_v1_team_project_user_path(
            team_id: @invalid_project.team.id,
            project_id: @invalid_project.id,
            id: user_assignment.id
          ),
          params: request_body.to_json,
          headers: @valid_headers
        )

        expect(response).to have_http_status(403)
      end
    end
  end
end
