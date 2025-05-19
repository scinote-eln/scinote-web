# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ProtocolsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @experiment = create(:experiment, created_by: @user, last_modified_by: @user, project: @project)
    @task = create(:my_module, created_by: @user, last_modified_by: @user, experiment: @experiment)

    @valid_headers = { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET protocols, #index' do
    it 'Response with correct protocols' do
      hash_body = nil
      get api_v1_team_project_experiment_task_protocols_path(
        team_id: @team,
        project_id: @project,
        experiment_id: @experiment,
        task_id: @task
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@task.protocols, each_serializer: Api::V1::ProtocolSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, non existing task' do
      hash_body = nil
      get api_v1_team_project_experiment_task_protocols_path(
        team_id: @team,
        project_id: @project,
        experiment_id: @experiment,
        task_id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET task, #show' do
    it 'When valid request, user can read protocol' do
      hash_body = nil
      get api_v1_team_project_experiment_task_protocol_path(
        team_id: @team,
        project_id: @project,
        experiment_id: @experiment,
        task_id: @task,
        id: @task.protocol
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@task.protocol, serializer: Api::V1::ProtocolSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, non existing protocol' do
      hash_body = nil
      get api_v1_team_project_experiment_task_protocol_path(
        team_id: @team.id,
        project_id: @project,
        experiment_id: @experiment,
        task_id: @task,
        id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'PATCH task, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      patch(
        api_v1_team_project_experiment_task_protocol_path(
          team_id: @team,
          project_id: @project,
          experiment_id: @experiment,
          task_id: @task,
          id: @task.protocol
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'protocols',
            attributes: {
              name: 'New protocol name',
              description: 'New protocol description'
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
              type: 'protocols',
              attributes: hash_including(name: 'New protocol name', description: 'New protocol description')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'protocols',
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
