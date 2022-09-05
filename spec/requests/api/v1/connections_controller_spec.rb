# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ConnectionsController', type: :request do
  before :all do
    MyModuleStatusFlow.ensure_default

    @user = create(:user)
    @another_user = create(:user)
    @team1 = create(:team, created_by: @user)
    @team2 = create(:team, created_by: @another_user)

    @valid_project = create(:project, name: Faker::Name.unique.name,
                            created_by: @user, team: @team1)

    @unaccessible_project = create(:project, name: Faker::Name.unique.name,
                                   created_by: @another_user, team: @team2)

    @valid_experiment = create(:experiment, created_by: @user,
      last_modified_by: @user, project: @valid_project)
    @unaccessible_experiment = create(:experiment, created_by: @another_user,
      last_modified_by: @another_user, project: @unaccessible_project)
    create_list(:my_module, 3, :with_due_date, created_by: @user,
                last_modified_by: @user, experiment: @valid_experiment)
    create_list(:my_module, 3, :with_due_date, created_by: @another_user,
                last_modified_by: @another_user, experiment: @unaccessible_experiment)

    MyModule.where(experiment: @valid_experiment).each_slice(2) do |input_my_module, output_my_module|
      Connection.create(
        from: output_my_module,
        to: input_my_module
      )
    end

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET connections, #index' do
    it 'Response with correct connections' do
      hash_body = nil
      get api_v1_team_project_experiment_connections_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_experiment.connections, each_serializer: Api::V1::ConnectionSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, experiment from another project' do
      hash_body = nil
      get api_v1_team_project_experiment_connections_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @unaccessible_experiment
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_connections_path(
        team_id: @team2.id,
        project_id: @unaccessible_project,
        experiment_id: @unaccessible_experiment
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_connections_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET connection, #show' do
    it 'When valid request, user can read connection' do
      hash_body = nil
      get api_v1_team_project_experiment_connection_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: @valid_experiment.connections.first.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(@valid_experiment.connections.first, serializer: Api::V1::ConnectionSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_project_experiment_connection_path(
        team_id: @team2.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: @valid_experiment.my_modules.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing connection' do
      hash_body = nil
      get api_v1_team_project_experiment_connection_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: -1
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, connection from unaccessible experiment' do
      hash_body = nil
      get api_v1_team_project_experiment_connection_path(
        team_id: @team1.id,
        project_id: @valid_project,
        experiment_id: @valid_experiment,
        id: @unaccessible_experiment.my_modules.first.id
      ), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'POST connections, #create' do
    before :all do
      create :user_project, :normal_user, user: @user, project: @valid_project
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:request_body) do
      {
        data: {
          type: 'connections',
          attributes: {
            input_id: @valid_experiment.my_modules.pluck(:id).first,
            output_id: @valid_experiment.my_modules.pluck(:id).last
          }
        }
      }
    end

    context 'when has valid params' do
      let(:action) do
        post(api_v1_team_project_experiment_connections_path(
               team_id: @team1.id,
               project_id: @valid_project.id,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)
      end

      it 'creates new connection' do
        expect { action }.to change { Connection.count }.by(1)
      end

      it 'returns status 200' do
        action

        expect(response).to have_http_status 200
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          ActiveModelSerializers::SerializableResource
            .new(@valid_experiment.connections.last, serializer: Api::V1::ConnectionSerializer).as_json
        )
      end
    end

    context 'when has not valid params' do
      it 'renders 404 when project not found' do
        post(api_v1_team_project_experiment_connections_path(
               team_id: @team1.id,
               project_id: -1,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(404)
      end

      it 'renders 403 when user is not member of the team' do
        post(api_v1_team_project_experiment_connections_path(
               team_id: @team2.id,
               project_id: @valid_project.id,
               experiment_id: @valid_experiment.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)

        expect(response).to have_http_status(403)
      end
    end
  end
end
