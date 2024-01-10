# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe 'Api::V2::ResultElements::TextsController', type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team, created_by: user) }
  let(:project) { create(:project, team: team, created_by: user) }
  let(:experiment) { create(:experiment, :with_tasks, project: project, created_by: user) }
  let(:task) { experiment.my_modules.first }
  let(:result) { create(:result, user: user, my_module: task) }
  let(:result_archived) { create(:result, :archived, user: user, my_module: task) }
  let(:valid_headers) { { Authorization: "Bearer #{generate_token(user.id)}", 'Content-Type': 'application/json' } }

  let(:api_path) do
    api_v2_team_project_experiment_task_result_texts_path(
      team_id: team.id,
      project_id: project.id,
      experiment_id: experiment.id,
      task_id: task.id,
      result_id: result.id
    )
  end

  describe 'GET result_texts, #index' do
    let!(:result_orderable_element) { create(:result_orderable_element, :result_text, result: result) }

    context 'when has valid params' do
      it 'renders 200' do
        get api_path, headers: valid_headers

        expect(response).to have_http_status(200)
        hash_body = nil
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match_array(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(result.result_texts, each_serializer: Api::V2::ResultTextSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when result is not found' do
      it 'renders 404' do
        get api_v2_team_project_experiment_task_result_texts_path(
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

  describe 'GET result_text, #show' do
    let(:result_text) { create(:result_text, result: result) }

    context 'when has valid params' do
      it 'renders 200' do
        hash_body = nil
        get api_v2_team_project_experiment_task_result_text_path(
          team_id: team.id,
          project_id: project.id,
          experiment_id: experiment.id,
          task_id: task.id,
          result_id: result.id,
          id: result_text.id
        ), headers: valid_headers

        expect(response).to have_http_status(200)
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(result_text, serializer: Api::V2::ResultTextSerializer)
              .to_json
          )['data']
        )
      end
    end
  end

  describe 'POST result_text, #create' do
    let(:action) do
      post(api_path, params: request_body.to_json, headers: valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'result_texts',
            attributes: {
              name: 'Result text',
              text: '<p>Hello!</p>'
            }
          }
        }
      end

      it 'creates new result_text' do
        expect { action }.to change { ResultText.count }.by(1)
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
              .new(ResultText.last, serializer: Api::V2::ResultTextSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'result_texts',
            attributes: {}
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end

    context 'when include tinymce' do
      let(:request_body) do
        {
          data: {
            type: 'result_texts',
            attributes: {
              name: 'Result text',
              text: "Result text 1 <img src=\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAA" \
                    "AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE" \
                    "QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg=='\" data-mce-token=\"1\">"
            }
          },
          included: [
            {
              type: 'tiny_mce_assets',
              attributes: {
                file_data: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
                           'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
                           'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg==',
                file_token: '1',
                file_name: 'test.png'
              }
            }
          ]
        }
      end

      it 'Response with correct text result and TinyMCE images' do
        hash_body = nil
        action

        expect(response).to have_http_status 201
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(ResultText.last, serializer: Api::V2::ResultTextSerializer)
              .to_json
          )['data']
        )
        expect(ResultText.last.text).to include "data-mce-token=\"#{Base62.encode(TinyMceAsset.last.id)}\""
      end
    end
  end

  describe 'PATCH result_text, #update' do
    let(:result_text) { create(:result_text, result: result) }
    let(:result_text_archived) { create(:result_text, result: result_archived) }
    let(:action) do
      patch(api_v2_team_project_experiment_task_result_text_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result.id,
        id: result_text.id
      ), params: request_body.to_json, headers: valid_headers)
    end
    let(:action_archived) do
      patch(api_v2_team_project_experiment_task_result_text_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result_archived.id,
        id: result_text_archived.id
      ), params: request_body.to_json, headers: valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'result_texts',
            attributes: {
              name: 'Result text',
              text: '<h1>Hello!</h1>'
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
              .new(ResultText.last, serializer: Api::V2::ResultTextSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'result_texts',
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
            type: 'result_texts',
            attributes: {
              name: 'Result text',
              text: '<h1>Hello!</h1>'
            }
          }
        }
      end

      it 'renders 403' do
        action_archived

        expect(response).to have_http_status(403)
      end
    end

    context 'when include tinymce' do
      let(:request_body) do
        {
          data: {
            type: 'result_texts',
            attributes: {
              name: 'Result text',
              text: 'Result text 1 <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
                    'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
                    'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJgg==" data-mce-token="1">'
            }
          },
          included: [
            {
              type: 'tiny_mce_assets',
              attributes: {
                file_data: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
                           'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
                           'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg==',
                file_token: '1',
                file_name: 'test.png'
              }
            }
          ]
        }
      end

      it 'Response with correct text result and TinyMCE images' do
        hash_body = nil
        action

        expect(response).to have_http_status 200
        expect { hash_body = json }.not_to raise_exception
        expect(hash_body[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(ResultText.last, serializer: Api::V2::ResultTextSerializer)
              .to_json
          )['data']
        )
        expect(ResultText.last.text).to include "data-mce-token=\"#{Base62.encode(TinyMceAsset.last.id)}\""
      end
    end
  end

  describe 'DELETE result_text, #destroy' do
    let(:result_text) { create(:result_text, result: result) }
    let(:result_text_archived) { create(:result_text, result: result_archived) }
    let(:action) do
      delete(api_v2_team_project_experiment_task_result_text_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result.id,
        id: result_text.id
      ), headers: valid_headers)
    end

    let(:action_archived) do
      delete(api_v2_team_project_experiment_task_result_text_path(
        team_id: team.id,
        project_id: project.id,
        experiment_id: experiment.id,
        task_id: task.id,
        result_id: result_archived.id,
        id: result_text_archived.id
      ), headers: valid_headers)
    end

    it 'deletes result_text' do
      action
      expect(response).to have_http_status(200)
      expect(ResultText.where(id: result_text.id)).to_not exist
    end

    it 'does not delete result_text of archived result' do
      action_archived
      expect(response).to have_http_status(403)
      expect(ResultText.where(id: result_text_archived.id)).to exist
    end
  end
end

# rubocop:enable Metrics/BlockLength
