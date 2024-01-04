# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Api::V2::ResultElements::TablesController', type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team, created_by: user) }
  let(:project) { create(:project, team: team, created_by: user) }
  let(:experiment) { create(:experiment, :with_tasks, project: project, created_by: user) }
  let(:task) { experiment.my_modules.first }
  let(:result) { create(:result, user: user, my_module: task) }
  let(:result_archived) { create(:result, :archived, user: user, my_module: task) }
  let(:valid_headers) { { Authorization: "Bearer #{generate_token(user.id)}", 'Content-Type': 'application/json' } }

  let(:api_path) do
    api_v2_team_project_experiment_task_result_tables_path(
      team_id: team.id,
      project_id: project.id,
      experiment_id: experiment.id,
      task_id: task.id,
      result_id: result.id
    )
  end

  describe 'GET result_tables, #index' do
    let!(:result_orderable_element) { create(:result_orderable_element, :result_table, result: result) }

    context 'when has valid params' do
      it 'renders 200' do
        get api_path, headers: valid_headers

        expect(response).to have_http_status(200)
        hash_body = nil
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match_array(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(result.result_tables, each_serializer: Api::V2::ResultTableSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when result is not found' do
      it 'renders 404' do
        get api_v2_team_project_experiment_task_result_tables_path(
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: task.id,
          result_id: -1
        ), headers: valid_headers

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET result_table, #show' do
    let(:result_table) { create(:result_table, result: result) }

    context 'when has valid params' do
      it 'renders 200' do
        hash_body = nil
        get api_v2_team_project_experiment_task_result_table_path(
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: task.id,
          result_id: result.id,
          id: result_table.table.id
        ), headers: valid_headers

        expect(response).to have_http_status(200)
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(result_table, serializer: Api::V2::ResultTableSerializer)
              .to_json
          )['data']
        )
      end
    end
  end

  describe 'POST result_table, #create' do
    let(:action) do
      post(api_path, params: request_body.to_json, headers: valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {
              name: 'Result table',
              contents: '{"data": [["group/time", "1 dpi", "6 dpi", "", ""], ["PVYNTN", "1", "1", "", ""]]}'
            }
          }
        }
      end

      it 'creates new result_table' do
        expect { action }.to change { ResultTable.count }.by(1)
      end

      it 'returns status 201' do
        action

        expect(response).to have_http_status 201
      end

      it 'returns well-formatted response' do
        hash_body = nil
        action

        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(ResultTable.last, serializer: Api::V2::ResultTableSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {}
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end

  describe 'PATCH result_table, #update' do
    let(:result_table) { create(:result_table, result: result) }
    let(:result_table_archived) { create(:result_table, result: result_archived) }
    let(:action) do
      patch(api_v2_team_project_experiment_task_result_table_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result.id,
        id: result_table.table.id
      ), params: request_body.to_json, headers: valid_headers)
    end

    let(:action_archived) do
      patch(api_v2_team_project_experiment_task_result_table_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result_archived.id,
        id: result_table_archived.table.id
      ), params: request_body.to_json, headers: valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {
              name: 'Result table',
              contents: '{"data": [["group/time", "1 dpi", "6 dpi", "", ""], ["PVYNTN", "1", "1", "", ""]]}'
            }
          }
        }
      end

      it 'returns status 200' do
        action

        expect(response).to have_http_status 200
      end

      it 'returns well-formatted response' do
        hash_body = nil
        action

        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(ResultTable.last, serializer: Api::V2::ResultTableSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {}
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end

    context 'when result is archived' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {
              name: 'Result table',
              contents: '{"data": [["group/time", "1 dpi", "6 dpi", "", ""], ["PVYNTN", "1", "1", "", ""]]}'
            }
          }
        }
      end

      it 'renders 403' do
        action_archived

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE result_table, #destroy' do
    let(:result_table) { create(:result_table, result: result) }
    let(:result_table_archived) { create(:result_table, result: result_archived) }
    let(:delete_action) do
      delete(api_v2_team_project_experiment_task_result_table_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result.id,
        id: result_table.table.id
      ), headers: valid_headers)
    end

    let(:delete_action_archived) do
      delete(api_v2_team_project_experiment_task_result_table_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result_archived.id,
        id: result_table_archived.table.id
      ), headers: valid_headers)
    end

    it 'deletes result_table' do
      delete_action
      expect(response).to have_http_status(200)
      expect(ResultTable.where(id: result_table.id)).to_not exist
      expect(Table.where(id: result_table.table.id)).to_not exist
    end

    it 'does not delete result_table of archived result' do
      delete_action_archived
      expect(response).to have_http_status(403)
      expect(ResultTable.where(id: result_table_archived.id)).to exist
      expect(Table.where(id: result_table_archived.table.id)).to exist
    end
  end
end

# rubocop:enable Metrics/BlockLength
