# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Api::V2::ResultsController', type: :request do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:team1) { create(:team, created_by: user) }
  let(:team2) { create(:team, created_by: another_user) }

  let(:valid_project) { create(:project, name: Faker::Name.unique.name, created_by: user, team: team1) }
  let(:unaccessible_project) { create(:project, name: Faker::Name.unique.name, created_by: user, team: team2) }

  let(:valid_experiment) { create(:experiment, created_by: user, last_modified_by: user, project: valid_project) }
  let(:unaccessible_experiment) { create(:experiment, created_by: user, last_modified_by: user, project: unaccessible_project) }

  let(:valid_task) { create(:my_module, created_by: user, last_modified_by: user, experiment: valid_experiment) }
  let(:unaccessible_task) { create(:my_module, created_by: user, last_modified_by: user, experiment: unaccessible_experiment) }

  let!(:results) { create_list(:result, 3, user: user, last_modified_by: user, my_module: valid_task) }
  let!(:unaccessible_result) { create(:result, user: user, last_modified_by: user, my_module: unaccessible_task) }

  let(:valid_hash_body) do
    {
      data: {
        type: 'results',
        attributes: {
          name: Faker::Name.unique.name
        }
      }
    }
  end

  let(:valid_headers) do
    {
      Authorization: "Bearer #{generate_token(user.id)}",
      'Content-Type': 'application/json'
    }
  end

  describe 'GET results, #index' do
    let(:api_path) do
      api_v2_team_project_experiment_task_results_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task
      )
    end

    it 'Response with correct results' do
      hash_body = nil
      get api_path, headers: valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(valid_task.results, each_serializer: Api::V2::ResultSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, task from another experiment' do
      hash_body = nil
      get api_v2_team_project_experiment_task_results_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: unaccessible_task
      ), headers: valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 404)
    end

    it 'When invalid request, user is not a member of the team' do
      hash_body = nil
      get api_v2_team_project_experiment_task_results_path(
        team_id: team2.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task
      ), headers: valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 403)
    end

    it 'When invalid request, non-existing task' do
      hash_body = nil
      get api_v2_team_project_experiment_task_results_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: -1
      ), headers: valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 404)
    end
  end

  describe 'GET result, #show' do
    let(:result_valid) { valid_task.results.first }
    let(:api_path) do
      api_v2_team_project_experiment_task_result_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task,
        id: result_valid.id
      )
    end

    it 'When valid request, user can read result' do
      hash_body = nil
      get api_path, headers: valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(result_valid, serializer: Api::V2::ResultSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user is not a member of the team' do
      hash_body = nil
      get api_v2_team_project_experiment_task_result_path(
        team_id: team2.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task,
        id: result_valid.id
      ), headers: valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 403)
    end

    it 'When invalid request, non-existing result' do
      hash_body = nil
      get api_v2_team_project_experiment_task_result_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task,
        id: -1
      ), headers: valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 404)
    end

    it 'When invalid request, result from an unaccessible task' do
      hash_body = nil
      get api_v2_team_project_experiment_task_result_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: unaccessible_task,
        id: unaccessible_result.id
      ), headers: valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 404)
    end
  end

  describe 'POST result, #create' do
    let(:api_path) do
      api_v2_team_project_experiment_task_results_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task
      )
    end

    it 'Response with correct result' do
      hash_body = nil
      post api_path, params: valid_hash_body.to_json, headers: valid_headers
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(Result.last, serializer: Api::V2::ResultSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, non-existing task' do
      hash_body = nil
      post api_v2_team_project_experiment_task_results_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: -1
      ), params: valid_hash_body.to_json, headers: valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 404)
    end

    it 'When invalid request, user is not a member of the team' do
      hash_body = nil
      post api_v2_team_project_experiment_task_results_path(
        team_id: team2.id,
        project_id: unaccessible_project,
        experiment_id: unaccessible_experiment,
        task_id: unaccessible_task
      ), params: valid_hash_body.to_json, headers: valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 403)
    end

    it 'When invalid request, task from another experiment' do
      hash_body = nil
      post api_v2_team_project_experiment_task_results_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: unaccessible_task
      ), params: valid_hash_body.to_json, headers: valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include(status: 404)
    end
  end

  describe 'PUT result, #update' do
    let(:result_valid) { valid_task.results.first }
    let(:request_body) do
      {
        data: {
          type: 'results',
          attributes: {
            name: 'my result'
          }
        }
      }
    end

    let(:action) do
      put(api_v2_team_project_experiment_task_result_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task,
        id: result_valid.id
      ), params: request_body.to_json, headers: valid_headers)
    end

    context 'when has attributes for update' do
      it 'updates tasks name' do
        action
        expect(result_valid.reload.name).to eq('my result')
      end

      it 'returns status 200' do
        action
        expect(response).to have_http_status 200
      end
    end

    context 'when there is nothing to update' do
      let(:request_body_with_same_name) do
        {
          data: {
            type: 'results',
            attributes: {
              name: result_valid.reload.name
            }
          }
        }
      end

      it 'returns 204' do
        put(api_v2_team_project_experiment_task_result_path(
          team_id: team1.id,
          project_id: valid_project,
          experiment_id: valid_experiment,
          task_id: valid_task,
          id: result_valid.id
        ), params: request_body_with_same_name.to_json, headers: valid_headers)

        expect(response).to have_http_status 204
      end
    end

    context 'when result is archived' do
      let(:result_archived) do
        create(:result, :archived, user: user, last_modified_by: user, my_module: valid_task)
      end

      let(:request_with_archived_result) do
        {
          data: {
            type: 'results',
            attributes: {
              name: 'Result archived'
            }
          }
        }
      end

      it 'returns 403' do
        put(api_v2_team_project_experiment_task_result_path(
          team_id: team1.id,
          project_id: valid_project,
          experiment_id: valid_experiment,
          task_id: valid_task,
          id: result_archived.id
        ), params: request_with_archived_result.to_json, headers: valid_headers)

        expect(response).to have_http_status 403
      end
    end
  end

  describe 'DELETE result, #destroy' do
    let(:result_archived) do
      create(:result, :archived, user: user, last_modified_by: user, my_module: valid_task)
    end

    let(:result_valid) { valid_task.results.first }

    let(:action) do
      delete(api_v2_team_project_experiment_task_result_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task,
        id: result_valid.id
      ), headers: valid_headers)
    end

    let(:action_archived) do
      delete(api_v2_team_project_experiment_task_result_path(
        team_id: team1.id,
        project_id: valid_project,
        experiment_id: valid_experiment,
        task_id: valid_task,
        id: result_archived.id
      ), headers: valid_headers)
    end

    it 'deletes result' do
      action_archived
      expect(response).to have_http_status(200)
      expect(Result.where(id: result_archived.id)).to_not exist
    end

    it 'does not delete archived result' do
      action
      expect(response).to have_http_status(403)
      expect(Result.where(id: result_valid.id)).to exist
    end
  end
end

# rubocop:enable Metrics/BlockLength
