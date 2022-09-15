# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::TaskUserAssignmentsController", type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team = create(:team, created_by: @user)
    @normal_user_role = create :normal_user_role
    @owner_role = UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
    @own_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @own_experiment = create :experiment,
                             name: Faker::Name.unique.name,
                             project: @own_project,
                             created_by: @user
    @own_task = create :my_module, name: Faker::Name.unique.name, experiment: @own_experiment, created_by: @own_experiment.created_by
    @invalid_project = create :project,
                              name: Faker::Name.unique.name,
                              created_by: @another_user,
                              team: @team,
                              visibility: :hidden
    @invalid_experiment = create :experiment,
                                 name: Faker::Name.unique.name,
                                 project: @invalid_project,
                                 created_by: @another_user
    @invalid_task = create :my_module, name: Faker::Name.unique.name, experiment: @invalid_experiment
    @technician_user_role = create :technician_role

    @valid_headers = { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET task_user_assignments, #index' do
    it 'Response with correct user assignments' do
      hash_body = nil
      get api_v1_team_project_experiment_task_user_assignments_path(
            team_id: @team.id,
            project_id: @own_project.id,
            experiment_id: @own_experiment.id,
            task_id: @own_task.id
          ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
                                    JSON.parse(ActiveModelSerializers::SerializableResource
                                      .new(@own_task.user_assignments, each_serializer: Api::V1::UserAssignmentSerializer)
                                      .to_json)['data']
                                  )
    end

    it 'When invalid request, user in not an owner of the task' do
      hash_body = nil
      get api_v1_team_project_experiment_task_user_assignments_path(
            team_id: @team.id,
            project_id: @invalid_project.id,
            experiment_id: @invalid_experiment.id,
            task_id: @invalid_task.id
          ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing task' do
      hash_body = nil
      get api_v1_team_project_experiment_task_user_assignments_path(
            team_id: @team.id,
            project_id: @own_project.id,
            experiment_id: @own_experiment.id,
            task_id: -1
          ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET user_assignment, #show' do
    it 'When valid request, user can read user assignment' do
      hash_body = nil
      get api_v1_team_project_experiment_task_user_assignment_path(
            team_id: @team.id,
            project_id: @own_project.id,
            experiment_id: @own_experiment.id,
            task_id: @own_task.id,
            id: @own_task.user_assignments.first.id
          ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
                                    JSON.parse(ActiveModelSerializers::SerializableResource
                                      .new(@own_task.user_assignments.first, serializer: Api::V1::UserAssignmentSerializer)
                                      .to_json)['data']
                                  )
    end

    it 'When invalid request, user in not member of the project' do
      hash_body = nil
      get api_v1_team_project_experiment_task_user_assignment_path(
            team_id: @team.id,
            project_id: @invalid_project.id,
            experiment_id: @invalid_experiment.id,
            task_id: @invalid_task.id,
            id: -1
          ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_experiment_task_user_assignment_path(
            team_id: @team.id,
            project_id: -1,
            experiment_id: -1,
            task_id: -1,
            id: -1
          ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'PATCH user_assignment, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      create :user_assignment,
             assignable: @own_project,
             user: @another_user,
             user_role: @normal_user_role,
             assigned_by: @user
      @user_assignment = create :user_assignment,
                                assignable: @own_task,
                                user: @another_user,
                                user_role: @normal_user_role,
                                assigned_by: @user
    end

    let(:action) do
      patch(
        api_v1_team_project_experiment_task_user_assignment_path(
          team_id: @own_project.team.id,
          project_id: @own_project.id,
          experiment_id: @own_experiment.id,
          task_id: @own_task.id,
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
                          hash_including(
                            data: hash_including(
                              type: 'user_assignments',
                              relationships: hash_including(
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
            type: 'user_assignments',
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
            type: 'user_assignments',
            attributes: {
              user_role_id: @technician_user_role.id
            }
          }
        }
      end

      it 'renders 403' do
        patch(
          api_v1_team_project_experiment_task_user_assignment_path(
            team_id: @invalid_project.team.id,
            project_id: @invalid_project.id,
            experiment_id: @invalid_experiment.id,
            task_id: @invalid_task.id,
            id: UserAssignment.last.id
          ),
          params: request_body.to_json,
          headers: @valid_headers
        )

        expect(response).to have_http_status(403)
      end
    end
  end
end
