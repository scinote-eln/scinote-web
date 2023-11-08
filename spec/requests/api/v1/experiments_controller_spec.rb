# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::ExperimentsController", type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, created_by: @user)
    @team2 = create(:team, created_by: @another_user)

    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @team1)

    @unaccessible_project = create(:project, name: Faker::Name.unique.name,
                                   created_by: @user, team: @team2)

    create_list(:experiment, 3, created_by: @user, last_modified_by: @user,
                project: @valid_project)
    create_list(:experiment, 2, created_by: @user, last_modified_by: @user,
                project: @valid_project, archived: true)
    create_list(:experiment, 3, created_by: @user, last_modified_by: @user,
                project: @unaccessible_project)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET experiments, #index' do
    it 'Response with correct experiments' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @team1.id,
        project_id: @valid_project), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_project.experiments,
                 each_serializer: Api::V1::ExperimentSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct experiments, only active' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @team1.id,
        project_id: @valid_project, filter: { archived: false }), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].pluck('attributes').pluck('archived').none?).to be(true)
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_project.experiments.active,
                 each_serializer: Api::V1::ExperimentSerializer)
            .to_json
        )['data']
      )
    end

    it 'Response with correct experiments, only archived' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @team1.id,
        project_id: @valid_project, filter: { archived: true }), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data].pluck('attributes').pluck('archived').all?).to be(true)
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_project.experiments.archived,
                 each_serializer: Api::V1::ExperimentSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, project from another team' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @team2.id,
        project_id: @valid_project), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @team2.id,
        project_id: @unaccessible_project), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing project' do
      hash_body = nil
      get api_v1_team_project_experiments_path(team_id: @team1.id,
        project_id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET experiment, #show' do
    it 'When valid request, user can read experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_path(team_id: @team1.id,
        project_id: @valid_project, id: @valid_project.experiments.first.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
        ActiveModelSerializers::SerializableResource
          .new(@valid_project.experiments.first,
               serializer: Api::V1::ExperimentSerializer)
          .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_path(
        team_id: @team2.id,
        project_id: @unaccessible_project,
        id: @unaccessible_project.experiments.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_path(team_id: @team1.id,
        project_id: @valid_project, id: -1),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, experiment from another project' do
      hash_body = nil
      get api_v1_team_project_experiment_path(
        team_id: @team1.id,
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
        team_id: @team1.id,
        project_id: @unaccessible_project,
        id: @unaccessible_project.experiments.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST experiment, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      post(
        api_v1_team_project_experiments_path(
          team_id: @valid_project.team.id,
          project_id: @valid_project
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'experiments',
            attributes: {
              name: 'Experiment name',
              description: 'Experiment description'
            }
          }
        }
      end

      it 'creates new experiment' do
        expect { action }.to change { Experiment.count }.by(1)
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
              type: 'experiments',
              attributes: hash_including(name: 'Experiment name', description: 'Experiment description')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'experiments',
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

  describe 'PATCH experiment, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
      @experiment = @valid_project.experiments.active.first
    end

    let(:action) do
      patch(
        api_v1_team_project_experiment_path(
          team_id: @valid_project.team.id,
          project_id: @valid_project.id,
          id: @experiment.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'experiments',
            attributes: {
              name: 'New experiment name',
              description: 'New experiment description',
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
              type: 'experiments',
              attributes: hash_including(
                name: 'New experiment name', description: 'New experiment description', archived: true
              )
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'experiments',
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
