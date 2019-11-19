# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TasksController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)

    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @teams.first)

    @unaccessible_project = create(:project, name: Faker::Name.unique.name,
                                   created_by: @user, team: @teams.second)

    @valid_experiment = create(:experiment, created_by: @user,
      last_modified_by: @user, project: @valid_project)
    @unaccessible_experiment = create(:experiment, created_by: @user,
      last_modified_by: @user, project: @unaccessible_project)

    create_list(:my_module, 3, created_by: @user,
                last_modified_by: @user, experiment: @valid_experiment)
    create_list(:my_module, 3, created_by: @user,
                last_modified_by: @user, experiment: @unaccessible_experiment)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET tasks, #index' do
    it 'Response with correct tasks' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_experiment.my_modules,
               each_serializer: Api::V1::TaskSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, experiment from another project' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @unaccessible_experiment
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @teams.second.id,
        project_id: @unaccessible_project,
        experiment_id: @unaccessible_experiment
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET task, #show' do
    it 'When valid request, user can read task' do
      hash_body = nil
      get api_v1_team_project_experiment_task_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: @valid_experiment.my_modules.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_experiment.my_modules.first,
               serializer: Api::V1::TaskSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_task_path(
        team_id: @teams.second.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: @valid_experiment.my_modules.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing task' do
      hash_body = nil
      get api_v1_team_project_experiment_task_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, task from unaccessible experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_task_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: @unaccessible_experiment.my_modules.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST tasks, #create' do
    before :all do
      create :user_project, :normal_user, user: @user, project: @valid_project
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:request_body) do
      {
        data: {
          type: 'tasks',
          attributes: {
            name: 'task name',
            x: 1,
            y: 4
          }
        }
      }
    end

    context 'when has valid params' do
      let(:action) do
        post(api_v1_team_project_experiment_tasks_path(
               team_id: @teams.first.id,
               project_id: @valid_project.id,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)
      end

      it 'creates new my module' do
        expect { action }.to change { MyModule.count }.by(1)
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
              type: 'tasks',
              attributes: hash_including(name: 'task name'),
              relationships: hash_including(outputs: { data: [] }, inputs: { data: [] })
            )
          )
        )
      end
    end

    context 'when has not valid params' do
      it 'renders 404 when project not found' do
        post(api_v1_team_project_experiment_tasks_path(
               team_id: @teams.first.id,
               project_id: -1,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(404)
      end

      it 'renders 403 when user is not member of the team' do
        post(api_v1_team_project_experiment_tasks_path(
               team_id: @teams.second.id,
               project_id: @valid_project.id,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(403)
      end

      it 'renders 403 for use with view permissions' do
        up = UserProject.where(user: @user, project: @valid_project).first
        up.update_attribute(:role, :viewer)

        post(api_v1_team_project_experiment_tasks_path(
               team_id: @teams.first.id,
               project_id: @valid_project.id,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(403)
      end
    end
  end
end
