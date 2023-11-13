# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ProjectsController', type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, created_by: @user)
    @team2 = create(:team, created_by: @another_user)

    # valid_projects
    2.times do
      project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team1)
    end
    2.times do
      project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team1, archived: true)
    end

    # unaccessable_projects
    create(:project, name: Faker::Name.unique.name,
                created_by: @another_user, team: @team2)
    create(:project, name: Faker::Name.unique.name,
                created_by: @another_user, team: @team2)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET projects, #index' do
    it 'Response with correct projects' do
      hash_body = nil
      get api_v1_team_projects_path(team_id: @team1.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@team1.projects, each_serializer: Api::V1::ProjectSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct projects, only active' do
      hash_body = nil
      get api_v1_team_projects_path(team_id: @team1.id, filter: { archived: false }),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].pluck('attributes').pluck('archived').none?).to be(true)
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@team1.projects.active, each_serializer: Api::V1::ProjectSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct projects, only archived' do
      hash_body = nil
      get api_v1_team_projects_path(team_id: @team1.id, filter: { archived: true }),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].pluck('attributes').pluck('archived').all?).to be(true)
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@team1.projects.archived, each_serializer: Api::V1::ProjectSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_projects_path(team_id: @team2.id),
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
      get api_v1_team_project_path(team_id: @team1.id,
                                id: @team1.projects.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@team1.projects.first, serializer: Api::V1::ProjectSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_path(team_id: @team2.id,
                                id: @team2.projects.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_path(team_id: @team1.id, id: -1),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, project from another team' do
      hash_body = nil
      get api_v1_team_project_path(team_id: @team1.id,
                                id: @team2.projects.first.id),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST project, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      post(api_v1_team_projects_path(team_id: @team1.id), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'projects',
            attributes: {
              name: 'Project name',
              visibility: 'hidden'
            }
          }
        }
      end

      it 'creates new project' do
        expect { action }.to change { Project.count }.by(1)
      end

      it 'returns status 201' do
        action

        expect(response).to have_http_status 201
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'projects',
              attributes: hash_including(name: 'Project name', visibility: 'hidden')
            )
          )
        )
      end

      context 'when includes project_folder relation' do
        let(:request_body) do
          {
            data: {
              type: 'projects',
              attributes: {
                name: 'Project name',
                visibility: 'hidden',
                project_folder_id: project_folder.id
              }
            }
          }
        end
        let(:project_folder) { create :project_folder, team: @team1 }

        it 'renders 201' do
          action

          expect(response).to have_http_status(201)
          expect(JSON.parse(response.body).dig('data', 'relationships', 'project_folder', 'data')).to be_truthy
        end

        context 'when folder from a different team' do
          let(:project_folder) { create :project_folder, team: @team2 }

          it do
            action

            expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Validation error'
            expect(response).to have_http_status 400
          end
        end
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'projects',
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

  describe 'PATCH project, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @project = @user.teams.first.projects.active.first
    end

    let(:action) do
      patch(
        api_v1_team_project_path(
          team_id: @project.team.id,
          id: @project.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'projects',
            attributes: {
              name: 'New project name',
              visibility: 'hidden',
              archived: true
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
              type: 'projects',
              attributes: hash_including(name: 'New project name', visibility: 'hidden', archived: true)
            )
          )
        )
      end

      context 'when includes project_folder relation' do
        let(:request_body) do
          {
            data: {
              type: 'projects',
              attributes: {
                project_folder_id: project_folder.id
              }
            }
          }
        end
        let(:project_folder) { create :project_folder, team: @team1 }

        it 'renders 201' do
          action

          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body).dig('data', 'relationships', 'project_folder', 'data')).to be_truthy
        end
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'projects',
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
