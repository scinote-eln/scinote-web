# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::ExperimentsController", type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)

    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @teams.first)

    @unaccessible_project = create(:project, name: Faker::Name.unique.name,
                                   created_by: @user, team: @teams.second)

    create_list(:experiment, 3, created_by: @user, last_modified_by: @user,
                project: @valid_project)
    create_list(:experiment, 3, created_by: @user, last_modified_by: @user,
                project: @unaccessible_project)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET experiments, #index' do
    it 'Response with correct experiments' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @teams.first.id,
        project_id: @valid_project), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_project.experiments,
               each_serializer: Api::V1::ExperimentSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, project from another team' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @teams.second.id,
        project_id: @valid_project), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @teams.second.id,
        project_id: @unaccessible_project), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @teams.first.id,
        project_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET experiment, #show' do
    it 'When valid request, user can read experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_path(team_id: @teams.first.id,
        project_id: @valid_project, id: @valid_project.experiments.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@valid_project.experiments.first,
               serializer: Api::V1::ExperimentSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_path(
        team_id: @teams.second.id,
        project_id: @unaccessible_project,
        id: @unaccessible_project.experiments.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_path(team_id: @teams.first.id,
        project_id: @valid_project, id: -1),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, experiment from another project' do
      hash_body = nil
      get api_v1_team_project_experiment_path(
        team_id: @teams.first.id,
        project_id: @valid_project,
        id: @unaccessible_project.experiments.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, experiment from unaccessible project' do
      hash_body = nil
      get api_v1_team_project_experiment_path(
        team_id: @teams.first.id,
        project_id: @unaccessible_project,
        id: @unaccessible_project.experiments.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end
end
