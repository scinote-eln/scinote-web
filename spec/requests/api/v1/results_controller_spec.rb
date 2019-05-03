# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::ResultsController", type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)

    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @teams.first)

    create(:user_project, user: @user, project: @valid_project, role: 0)

    @unaccessible_project = create(:project, name: Faker::Name.unique.name,
                                   created_by: @user, team: @teams.second)

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
        included:  [
          { type: 'result_texts',
            attributes: {
              text: Faker::Lorem.sentence(25)
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
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_task.results, each_serializer: Api::V1::ResultSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, task from another experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_task_results_path(
        team_id: @teams.first.id,
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
        team_id: @teams.second.id,
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
        team_id: @teams.first.id,
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
              text: 'Result text 1 [~tiny_mce_id:a1]'
            } },
          { type: 'tiny_mce_assets',
            attributes: {
              file_data: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAA'\
                         'AACCAIAAAD91JpzAAAACXBIWXMAAC4jAAAuIwF4pT92AAAAE0lE'\
                         'QVQIHWP8//8/AwMDExADAQAkBgMBOOSShwAAAABJRU5ErkJggg==',
              file_token: 'a1',
              file_name: 'test.png'
            } }
        ]
      }
    end

    it 'Response with correct text result' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: @valid_text_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(Result.last,
               serializer: Api::V1::ResultSerializer)
          .as_json[:data]
      )
      expect(hash_body[:included]).to match(
        ActiveModelSerializers::SerializableResource
          .new(Result.last, serializer: Api::V1::ResultSerializer,
               include: :text)
          .as_json[:included]
      )
    end

    it 'Response with correct text result and TinyMCE images' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: @valid_tinymce_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 201
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(Result.last, serializer: Api::V1::ResultSerializer)
          .as_json[:data]
      )
      expect(hash_body[:included]).to match(
        ActiveModelSerializers::SerializableResource
          .new(Result.last, serializer: Api::V1::ResultSerializer,
               include: :text)
          .as_json[:included]
      )
    end

    it 'When invalid request, mismatching file token' do
      invalid_hash_body = @valid_tinymce_hash_body
      invalid_hash_body[:included][1][:attributes][:file_token] = 'a2'
      post api_v1_team_project_experiment_task_results_path(
        team_id: @teams.first.id,
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
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task
      ), params: invalid_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status 400
    end

    it 'When invalid request, non existing task' do
      hash_body = nil
      post api_v1_team_project_experiment_task_results_path(
        team_id: @teams.first.id,
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
        team_id: @teams.second.id,
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
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @unaccessible_task
      ), params: @valid_text_hash_body.to_json, headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET result, #show' do
    it 'When valid request, user can read result' do
      hash_body = nil
      get api_v1_team_project_experiment_task_result_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        task_id: @valid_task,
        id: @valid_task.results.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_task.results.first, serializer: Api::V1::ResultSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_task_result_path(
        team_id: @teams.second.id,
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
        team_id: @teams.first.id,
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
        team_id: @teams.first.id,
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
end
