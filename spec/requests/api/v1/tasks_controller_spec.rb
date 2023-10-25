# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TasksController', type: :request do
  before :all do
    MyModuleStatusFlow.ensure_default

    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, :change_user_team, created_by: @user)
    @team2 = create(:team, created_by: @another_user)
    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @team1)

    @unaccessible_project = create(:project, name: Faker::Name.unique.name,
                                   created_by: @another_user, team: @team2)

    @valid_experiment = create(:experiment, created_by: @user,
      last_modified_by: @another_user, project: @valid_project)
    @unaccessible_experiment = create(:experiment, created_by: @another_user,
      last_modified_by: @another_user, project: @unaccessible_project)
    create_list(:my_module, 3, :with_due_date, created_by: @user,
                last_modified_by: @user, experiment: @valid_experiment)
    create_list(:my_module, 2, :with_due_date, created_by: @user,
                last_modified_by: @user, experiment: @valid_experiment, archived: true)
    create_list(:my_module, 3, :with_due_date, created_by: @another_user,
                last_modified_by: @another_user, experiment: @unaccessible_experiment)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET tasks, #index' do
    it 'Response with correct tasks' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_experiment.my_modules, each_serializer: Api::V1::TaskSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct tasks, only active' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        filter: { archived: false }
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].pluck('attributes').pluck('archived').none?).to be(true)
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_experiment.my_modules.active, each_serializer: Api::V1::TaskSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct tasks, only archived' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        filter: { archived: true }
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].pluck('attributes').pluck('archived').all?).to be(true)
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_experiment.my_modules.archived, each_serializer: Api::V1::TaskSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, experiment from another project' do
      hash_body = nil
      get api_v1_team_project_experiment_tasks_path(
        team_id: @team1.id,
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
        team_id: @team2.id,
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
        team_id: @team1.id,
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
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: @valid_experiment.my_modules.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_experiment.my_modules.first, serializer: Api::V1::TaskSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_task_path(
        team_id: @team2.id,
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
        team_id: @team1.id,
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
        team_id: @team1.id,
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
      create :user_project, user: @user, project: @valid_project
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
               team_id: @team1.id,
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
               team_id: @team1.id,
               project_id: -1,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(404)
      end

      it 'renders 403 when user is not member of the team' do
        post(api_v1_team_project_experiment_tasks_path(
               team_id: @team2.id,
               project_id: @valid_project.id,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(403)
      end

      it 'renders 403 for use with view permissions' do
        user_assignment = UserAssignment.where(user: @user, assignable: @valid_experiment).first
        user_assignment.update!(user_role: create(:viewer_role))

        post(api_v1_team_project_experiment_tasks_path(
               team_id: @team1.id,
               project_id: @valid_project.id,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'PATCH task, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:task) { @valid_experiment.my_modules.active.first }

    let(:action) do
      patch(
        api_v1_team_project_experiment_task_path(
          team_id: @valid_project.team.id,
          project_id: @valid_project.id,
          experiment_id: @valid_experiment.id,
          id: task.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'tasks',
            attributes: {
              name: 'New task name',
              description: 'New description about task'
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
              type: 'tasks',
              attributes: hash_including(name: 'New task name', description: 'New description about task')
            )
          )
        )
      end
    end

    context 'direct task completion disabled, when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'tasks',
            attributes: {
              state: 'completed'
            }
          }
        }
      end

      it 'returns status 204, no changes to task' do
        action

        expect(response).to have_http_status 204
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'tasks',
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
  end
end
