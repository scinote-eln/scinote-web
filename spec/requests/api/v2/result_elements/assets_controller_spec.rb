# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Api::V2::ResultElements::AssetsController', type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team, created_by: user) }
  let(:project) { create(:project, team: team, created_by: user) }
  let(:experiment) { create(:experiment, :with_tasks, project: project, created_by: user) }
  let(:task) { experiment.my_modules.first }
  let(:result) { create(:result, user: user, my_module: task) }
  let(:result_archived) { create(:result, :archived, user: user, my_module: task) }
  let(:valid_headers) { { Authorization: "Bearer #{generate_token(user.id)}", 'Content-Type': 'application/json' } }

  let(:api_path) do
    api_v2_team_project_experiment_task_result_assets_path(
      team_id: team.id,
      project_id: project.id,
      experiment_id: experiment.id,
      task_id: task.id,
      result_id: result.id
    )
  end

  describe 'GET result assets, #index' do
    let(:result_asset) { create(:result_asset, result: result) }

    context 'when has valid params' do
      it 'renders 200' do
        get api_path, headers: valid_headers

        expect(response).to have_http_status(200)
        hash_body = nil
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match_array(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(result.result_assets, each_serializer: Api::V2::AssetSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when result is not found' do
      it 'renders 404' do
        get api_v2_team_project_experiment_task_result_assets_path(
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

  describe 'GET result_asset, #show' do
    let(:result_asset) { create(:result_asset, result: result) }

    context 'when has valid params' do
      it 'renders 200' do
        hash_body = nil
        get api_v2_team_project_experiment_task_result_asset_path(
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: task.id,
          result_id: result.id,
          id: result_asset.asset.id
        ), headers: valid_headers

        expect(response).to have_http_status(200)
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(result_asset.asset, serializer: Api::V2::AssetSerializer)
              .to_json
          )['data']
        )
      end
    end
  end

  describe 'POST result_asset, #create' do
    let(:action) do
      post(api_path, params: request_body.to_json, headers: valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'attachments',
            attributes: {
              file_data: "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lEQVQIHWP8//8/
                          AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg=='\''",
              file_type: 'image/jpeg',
              file_name: 'test.jpg'
            }
          }
        }
      end

      it 'creates new result_asset' do
        expect { action }.to change { ResultAsset.count }.by(1)
      end

      it 'returns status 201' do
        action

        expect(response).to have_http_status(201)
      end

      it 'returns well-formatted response' do
        hash_body = nil
        action

        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(ResultAsset.last.asset, serializer: Api::V2::AssetSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'attachments',
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

  describe 'DELETE result_asset, #destroy' do
    let(:result_asset) { create(:result_asset, result: result) }
    let(:result_asset_archived) { create(:result_asset, result: result_archived) }

    let(:action) do
      delete(api_v2_team_project_experiment_task_result_asset_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result.id,
        id: result_asset.asset.id
      ), headers: valid_headers)
    end

    let(:action_archived) do
      delete(api_v2_team_project_experiment_task_result_asset_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result_archived.id,
        id: result_asset_archived.asset.id
      ), headers: valid_headers)
    end

    it 'deletes result_asset' do
      action
      expect(response).to have_http_status(200)
      expect(ResultAsset.where(id: result_asset.id)).to_not exist
      expect(Asset.where(id: result_asset.asset.id)).to_not exist
    end

    it 'does not delete result_asset of archived result' do
      action_archived
      expect(response).to have_http_status(403)
      expect(ResultAsset.where(id: result_asset_archived.id)).to exist
      expect(Asset.where(id: result_asset_archived.asset.id)).to exist
    end
  end
end

# rubocop:enable Metrics/BlockLength
