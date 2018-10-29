# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::ResultsController", type: :request do
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

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
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
      expect(hash_body).to match({})
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
      expect(hash_body).to match({})
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
      expect(hash_body).to match({})
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
      expect(hash_body).to match({})
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
      expect(hash_body).to match({})
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
      expect(hash_body).to match({})
    end
  end
end
