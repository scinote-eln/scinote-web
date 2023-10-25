# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ResultsController', type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, created_by: @user)
    @team2 = create(:team, created_by: @another_user)

    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @team1)

    @unaccessible_project = create(:project, name: Faker::Name.unique.name,
                                   created_by: @user, team: @team2)

    @valid_experiment = create(:experiment, created_by: @user,
      last_modified_by: @user, project: @valid_project)
    @unaccessible_experiment = create(:experiment, created_by: @user,
      last_modified_by: @user, project: @unaccessible_project)

    @valid_task = create(:my_module, created_by: @user,
      last_modified_by: @user, experiment: @valid_experiment)
    @unaccessible_task = create(:my_module, created_by: @user,
      last_modified_by: @user, experiment: @unaccessible_experiment)

    create(:result_text, result: create(
      :result, user: @user, last_modified_by: @user, my_module: @valid_task
    ))
    create(:result_table, result: create(
      :result, user: @user, last_modified_by: @user, my_module: @valid_task
    ))
    create(:result_asset, result: create(
      :result, user: @user, last_modified_by: @user, my_module: @valid_task
    ))

    create(:result_text, result:
      create(:result, user: @user, last_modified_by: @user,
             my_module: @unaccessible_task))

    @valid_text_hash_body =
      { data:
        { type: 'results',
          attributes: {
            name: Faker::Name.unique.name
          } },
        included: [
          { type: 'result_texts',
            attributes: {
              text: Faker::Lorem.sentence(word_count: 25)
            } }
        ] }

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id),
        'Content-Type': 'application/json' }
  end

  describe 'GET results, #index' do
    it 'Response with correct results' do
      hash_body = nil
      get api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_task.results, each_serializer: Api::V1::ResultSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, task from another experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @unaccessible_task
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_task_results_path(
        team_id: @team2.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing task' do
      hash_body = nil
      get api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST result, #create' do
    before :all do
      @valid_tinymce_hash_body = {
        data:
          { type: 'results',
            attributes: {
              name: Faker::Name.unique.name
            } },
        included: [
          { type: 'result_texts',
            attributes: {
              text: 'Result text 1 <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
                         'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
                         'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg==" data-mce-token="1">'
            } },
          { type: 'tiny_mce_assets',
            attributes: {
              file_data: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
                         'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
                         'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg==',
              file_token: '1',
              file_name: 'test.png'
            } }
        ]
      }
    end

    it 'Response with correct text result' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: @valid_text_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(Result.last, serializer: Api::V1::ResultSerializer)
            .to_json
        )['data']
      )
      expect(hash_body[:included]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(Result.last, serializer: Api::V1::ResultSerializer, include: :text)
            .to_json
        )['included']
      )
    end

    it 'Response with correct text result and TinyMCE images' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: @valid_tinymce_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(Result.last, serializer: Api::V1::ResultSerializer)
            .to_json
        )['data']
      )
      expect(hash_body[:included]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(Result.last, serializer: Api::V1::ResultSerializer, include: :text)
            .to_json
        )['included']
      )
      expect(ResultText.last.text).to include "data-mce-token=\"#{Base62.encode(TinyMceAsset.last.id)}\""
    end

    it 'Response correct with old TinyMCE images' do
      hash_body = nil
      @valid_tinymce_hash_body[:included][0][:attributes][:text] = 'Result text 1 [~tiny_mce_id:1]'
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: @valid_tinymce_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(ResultText.last.text).to include "data-mce-token=\"#{Base62.encode(TinyMceAsset.last.id)}\""
    end

    it 'When invalid request, mismatching file token' do
      invalid_hash_body = @valid_tinymce_hash_body
      invalid_hash_body[:included][1][:attributes][:file_token] = 'a2'
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: invalid_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
    end

    it 'When invalid request, missing file reference in text' do
      invalid_hash_body = @valid_tinymce_hash_body
      invalid_hash_body[:included][0][:attributes][:text] = 'Result text 1'
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: invalid_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
    end

    it 'When invalid request, non existing task' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: -1
      ), params: @valid_text_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team2.id,
        project_id: @unaccessible_project,
        experiment_id: @unaccessible_experiment,
        task_id: @unaccessible_task
      ), params: @valid_text_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, task from another experiment' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @unaccessible_task
      ), params: @valid_text_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    context 'when resultType is File' do
      let(:request_body) do
        {
          data: {
            type: 'results',
            attributes: {
              name: 'my result'
            }
          },
          included: [{ type: 'result_files', attributes: attributes }]
        }
      end

      let(:action) do
        post(api_v1_team_project_experiment_task_results_path(
          team_id: @team1.id,
          project_id: @valid_project,
          experiment_id: @valid_experiment,
          task_id: @valid_task
        ), params: request_body, headers: @valid_headers)
      end

      context 'when sending base64' do
        let(:filedata_base64) do
          'iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
          'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
          'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg=='
        end
        let(:attributes) do
          {
            file_data: filedata_base64,
            file_name: 'file.png',
            file_type: 'image/png'
          }
        end
        let(:request_body) { super().to_json }

        it 'creates new asset' do
          expect { action }.to change { ResultAsset.count }.by(1)
        end

        it 'returns status 201' do
          action

          expect(response).to have_http_status 201
        end
      end

      context 'when sending multipart form' do
        let(:attributes) { { file: Rack::Test::UploadedFile.new(file_fixture('test.jpg').open) } }

        it 'creates new asset' do
          expect { action }.to change { ResultAsset.count }.by(1)
        end

        it 'returns status 201' do
          action

          expect(response).to have_http_status 201
        end
      end
    end
  end

  describe 'GET result, #show' do
    it 'When valid request, user can read result' do
      hash_body = nil
      get api_v1_team_project_experiment_task_result_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task,
        id: @valid_task.results.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_task.results.first, serializer: Api::V1::ResultSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_task_result_path(
        team_id: @team2.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task,
        id: @valid_task.results.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing result' do
      hash_body = nil
      get api_v1_team_project_experiment_task_result_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task,
        id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, result from unaccessible task' do
      hash_body = nil
      get api_v1_team_project_experiment_task_result_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @unaccessible_task,
        id: @unaccessible_task.results.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'PUT result, #update' do
    context 'when resultType is file' do
      let(:result_file) { @valid_task.results.last }
      let(:file) { Rack::Test::UploadedFile.new(file_fixture('test.jpg').open) }
      let(:request_body) do
        {
          data: {
            type: 'results',
            attributes: {
              name: 'my result'
            }
          },
          included: [
            { type: 'result_files',
              attributes: {
                file: file
              } }
          ]
        }
      end
      let(:action) do
        put(api_v1_team_project_experiment_task_result_path(
          team_id: @team1.id,
          project_id: @valid_project,
          experiment_id: @valid_experiment,
          task_id: @valid_task,
          id: result_file.id
        ), params: request_body, headers: @valid_headers)
      end

      context 'when has attributes for update' do
        it 'updates tasks name' do
          action

          expect(result_file.reload.name).to eq('my result')
        end

        it 'returns status 200' do
          action

          expect(response).to have_http_status 200
        end
      end

      context 'when has new image for update' do
        let(:action) do
          put(api_v1_team_project_experiment_task_result_path(
            team_id: @team1.id,
            project_id: @valid_project,
            experiment_id: @valid_experiment,
            task_id: @valid_task,
            id: result_file.id
          ), params: request_body, headers: @valid_headers)
        end

        let(:request_body) do
          {
            data: { type: 'results', attributes: { name: result_file.reload.name } },
            included: [{ type: 'result_files', attributes: attributes }]
          }
        end

        context 'when sending base64' do
          let(:filedata_base64) do
            'iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
          'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
          'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg=='
          end
          let(:attributes) do
            {
              file_data: filedata_base64,
              file_name: 'file.png',
              file_type: 'image/png'
            }
          end
          let(:request_body) { super().to_json }

          it 'returns status 200' do
            action

            expect(response).to have_http_status 200
          end
        end

        context 'when sending multipart form' do
          let(:attributes) { { file: Rack::Test::UploadedFile.new(file_fixture('apple.jpg').open) } }

          it 'returns status 200' do
            action

            expect(response).to have_http_status 200
          end
        end
      end

      context 'when there is nothing to update' do
        let(:request_body_with_same_name) do
          {
            data: {
              type: 'results',
              attributes: {
                name: result_file.reload.name
              }
            }
          }
        end

        it 'returns 204' do
          put(api_v1_team_project_experiment_task_result_path(
            team_id: @team1.id,
            project_id: @valid_project,
            experiment_id: @valid_experiment,
            task_id: @valid_task,
            id: result_file.id
          ), params: request_body_with_same_name.to_json, headers: @valid_headers)

          expect(response).to have_http_status 204
        end
      end
    end

    # ### Refactor without instance variables
    #
    # context 'when resultType is text' do
    #   let(:result_text) { @valid_task.results.first }
    #   let(:action) do
    #     put(api_v1_team_project_experiment_task_result_path(
    #           team_id: @team1.id,
    #           project_id: @valid_project,
    #           experiment_id: @valid_experiment,
    #           task_id: @valid_task,
    #           id: result_text.id
    #         ), params: @valid_text_hash_body.to_json, headers: @valid_headers)
    #   end
    #
    #   it 'returns status 500' do
    #     action
    #
    #     expect(response).to have_http_status 500
    #   end
    # end
  end
end
