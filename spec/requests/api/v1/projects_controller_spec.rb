# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::ProjectsController", type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)

    # valid_projects
    create(:project, name: Faker::Name.unique.name,
            created_by: @user, team: @teams.first)
    create(:project, name: Faker::Name.unique.name,
            created_by: @user, team: @teams.first)

    # unaccessable_projects
    create(:project, name: Faker::Name.unique.name,
                created_by: @user, team: @teams.second)
    create(:project, name: Faker::Name.unique.name,
                created_by: @user, team: @teams.second)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET projects, #index' do
    it 'Response with correct projects' do
      hash_body = nil
      get api_v1_team_projects_path(team_id: @teams.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@teams.first.projects,
               each_serializer: Api::V1::ProjectSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_projects_path(team_id: @teams.second.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing team' do
      hash_body = nil
      get api_v1_team_projects_path(team_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET project, #show' do
    it 'When valid request, user can read project' do
      hash_body = nil
      get api_v1_team_project_path(team_id: @teams.first.id,
                                id: @teams.first.projects.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@teams.first.projects.first,
               serializer: Api::V1::ProjectSerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_path(team_id: @teams.second.id,
                                id: @teams.second.projects.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_path(team_id: @teams.first.id, id: -1),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, project from another team' do
      hash_body = nil
      get api_v1_team_project_path(team_id: @teams.first.id,
                                id: @teams.second.projects.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end
end
