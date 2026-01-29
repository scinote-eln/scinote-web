# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V2::TaskUserGroupAssignmentsController", type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @group_user = create(:user)
    @team = create(:team, created_by: @user)
    @user_group = create(:user_group, team: @team, created_by: @user, last_modified_by: @user)
    @another_user_group = create(:user_group, team: @team, created_by: @user, last_modified_by: @user)
    @normal_user_role = create :normal_user_role
    create(:user_group_membership, user: @user, user_group: @user_group, created_by: @user)
    create(:user_group_membership, user: @another_user, user_group: @another_user_group, created_by: @user)
    create_user_assignment(@team, @normal_user_role, @another_user)
    create_user_assignment(@team, @normal_user_role, @group_user)
    @project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @experiment = create(:experiment, name: Faker::Name.unique.name, created_by: @user, project: @project)
    @task = create(:my_module, name: Faker::Name.unique.name, created_by: @user, experiment: @experiment)
    @owner_role = UserRole.find_predefined_owner_role
    create_user_group_assignment(@task, @owner_role, @user_group)
    @invalid_project = create(:project, name: Faker::Name.unique.name, created_by: @another_user, team: @team, visibility: :hidden)
    @invalid_experiment = create(:experiment, name: Faker::Name.unique.name, created_by: @another_user, project: @invalid_project)
    @invalid_task = create(:my_module, name: Faker::Name.unique.name, created_by: @another_user, experiment: @invalid_experiment)

    @valid_headers = { Authorization: "Bearer #{generate_token(@user.id)}" }
    @valid_headers_group_user = { Authorization: "Bearer #{generate_token(@group_user.id)}" }
    @valid_headers_another_user = { Authorization: "Bearer #{generate_token(@another_user.id)}" }
  end

  describe 'GET #index' do
    it 'Response with correct user group experiment assignments' do
      hash_body = nil
      get api_v2_team_project_experiment_task_user_group_assignments_path(team_id: @team.id, project_id: @project.id, experiment_id: @experiment.id, task_id: @task.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(ActiveModelSerializers::SerializableResource
          .new(@task.user_group_assignments, each_serializer: Api::V2::UserGroupAssignmentSerializer)
          .to_json)['data']
      )
    end

    it 'When invalid request, user do not have access to experiment' do
      hash_body = nil
      get api_v2_team_project_experiment_task_user_group_assignments_path(team_id: @team.id, project_id: @project.id, experiment_id: @experiment.id, task_id: @task.id),
          headers: @valid_headers_another_user
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing experiment' do
      hash_body = nil
      get api_v2_team_project_experiment_task_user_group_assignments_path(team_id: @team.id, project_id: @project.id, experiment_id: @experiment.id, task_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET #show' do
    it 'When valid request, user can read experiment users' do
      hash_body = nil
      get api_v2_team_project_experiment_task_user_group_assignment_path(
        team_id: @team.id, project_id: @project.id, experiment_id: @experiment.id, task_id: @task.id, id: @task.user_group_assignments.order(:created_at).first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(ActiveModelSerializers::SerializableResource
          .new(@task.user_group_assignments.order(:created_at).first, serializer: Api::V2::UserGroupAssignmentSerializer)
          .to_json)['data']
      )
    end

    it 'When invalid request, user in not member of the experiment' do
      hash_body = nil
      get api_v2_team_project_experiment_task_user_group_assignment_path(
        team_id: @team.id, project_id: @invalid_project.id, experiment_id: @invalid_experiment.id, task_id: @invalid_task.id, id: @invalid_task.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
    end

    it 'When invalid request, non existing assignment' do
      hash_body = nil
      get api_v2_team_project_experiment_task_user_group_assignment_path(team_id: @team.id, project_id: @project.id, experiment_id: @experiment.id, task_id: @task.id, id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
    end
  end

  describe 'PATCH #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @technician_user_role = create :technician_role
    end

    let(:action) do
      patch(
        api_v2_team_project_experiment_task_user_group_assignment_path(
          team_id: @project.team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          id: @task.user_group_assignments.order(:created_at).last.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'user_group_assignments',
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
            .new(@task.user_group_assignments.order(:created_at).last, serializer: Api::V2::UserGroupAssignmentSerializer)
            .to_json)
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'user_group_assignments',
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

    context 'when user is not an owner of the experiment' do
      let(:request_body) do
        {
          data: {
            type: 'user_group_assignments',
            attributes: {
              user_role_id: @technician_user_role.id
            }
          }
        }
      end

      it 'renders 403' do
        patch(
          api_v2_team_project_experiment_task_user_group_assignment_path(
            team_id: @invalid_project.team.id,
            project_id: @invalid_project.id,
            experiment_id: @invalid_experiment.id,
            task_id: @invalid_task.id,
            id: -1
          ),
          params: request_body.to_json,
          headers: @valid_headers
        )

        expect(response).to have_http_status(403)
      end
    end
  end
end
