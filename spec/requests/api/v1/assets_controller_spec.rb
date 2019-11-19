# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::AssetsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team)
    @experiment = create(:experiment, :with_tasks, project: @project)
    @task = @experiment.my_modules.first
    @protocol = create(:protocol, my_module: @task)
    @step = create(:step, protocol: @protocol)

    create(:user_team, user: @user, team: @team)
    create(:user_project, :normal_user, user: @user, project: @project)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  let(:asset) { create :asset, step: @step }

  describe 'GET steps, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        create(:step_asset, step: @step, asset: asset)

        get(api_v1_team_project_experiment_task_protocol_step_assets_path(
              team_id: @team.id,
              project_id: @project.id,
              experiment_id: @experiment.id,
              task_id: @task.id,
              protocol_id: @protocol.id,
              step_id: @step.id
            ), headers: @valid_headers)

        expect(response).to have_http_status(200)
      end
    end

    context 'when protocol is not found' do
      it 'renders 404' do
        get(api_v1_team_project_experiment_task_protocol_step_assets_path(
              team_id: @team.id,
              project_id: @project.id,
              experiment_id: @experiment.id,
              task_id: @task.id,
              protocol_id: -1,
              step_id: @step.id
            ), headers: @valid_headers)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET step, #show' do
    context 'when has valid params' do
      it 'renders 200' do
        create(:step_asset, step: @step, asset: asset)

        get(api_v1_team_project_experiment_task_protocol_step_asset_path(
              team_id: @team.id,
              project_id: @project.id,
              experiment_id: @experiment.id,
              task_id: @task.id,
              protocol_id: @protocol.id,
              step_id: @step.id,
              id: asset.id
            ), headers: @valid_headers)

        expect(response).to have_http_status(200)
      end
    end

    context 'when experiment is not found' do
      it 'renders 404' do
        get(api_v1_team_project_experiment_task_protocol_step_asset_path(
              team_id: @team.id,
              project_id: @project.id,
              experiment_id: -1,
              task_id: @task.id,
              protocol_id: @protocol.id,
              step_id: @step.id,
              id: asset.id
            ), headers: @valid_headers)

        expect(response).to have_http_status(404)
      end
    end

    context 'when asset is not found' do
      it 'renders 404' do
        get(api_v1_team_project_experiment_task_protocol_step_asset_path(
              team_id: @team.id,
              project_id: @project.id,
              experiment_id: @experiment.id,
              task_id: @task.id,
              protocol_id: @protocol.id,
              step_id: @step.id,
              id: -1
            ), headers: @valid_headers)

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST step, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    before :each do
      @file = fixture_file_upload('files/test.jpg', 'image/jpg')
      allow_any_instance_of(Asset).to receive(:post_process_file)
    end

    let(:action) do
      post(api_v1_team_project_experiment_task_protocol_step_assets_path(
             team_id: @team.id,
             project_id: @project.id,
             experiment_id: @experiment.id,
             task_id: @task.id,
             protocol_id: @protocol.id,
             step_id: @step.id
           ),
           params: request_body,
           headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'attachments',
            attributes: {
              file: @file
            }
          }
        }
      end

      it 'creates new asset' do
        expect { action }.to change { Asset.count }.by(1)
      end

      it 'returns status 201' do
        action

        expect(response).to have_http_status 201
      end

      it 'calls post_process_file function for text extraction' do
        expect_any_instance_of(Asset).to receive(:post_process_file)

        action
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'attachments',
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
