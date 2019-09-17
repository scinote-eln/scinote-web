# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::StepsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team)
    @experiment = create(:experiment, :with_tasks, project: @project)
    @task = @experiment.my_modules.first
    create(:user_team, user: @user, team: @team)
    create(:user_project, :normal_user, user: @user, project: @project)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  let(:protocol) { create :protocol, my_module: @task }
  let(:steps) { create_list(:step, 3, protocol: protocol) }

  describe 'GET steps, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v1_team_project_experiment_task_protocol_steps_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: protocol.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when protocol is not found' do
      it 'renders 404' do
        get api_v1_team_project_experiment_task_protocol_steps_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: -1
        ), headers: @valid_headers

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET step, #show' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v1_team_project_experiment_task_protocol_step_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: protocol.id,
          id: steps.first.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when experiment is archived and permission checks fails' do
      it 'renders 403' do
        @experiment.update_attribute(:archived, true)

        get api_v1_team_project_experiment_task_protocol_step_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: protocol.id,
          id: steps.first.id
        ), headers: @valid_headers

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST step, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      post(api_v1_team_project_experiment_task_protocol_steps_path(
             team_id: @team.id,
             project_id: @project.id,
             experiment_id: @experiment.id,
             task_id: @task.id,
             protocol_id: protocol.id
           ),
           params: request_body.to_json,
           headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'steps',
            attributes: {
              name: 'Step name',
              description: 'Description about step'
            }
          }
        }
      end

      it 'creates new step' do
        expect { action }.to change { Step.count }.by(1)
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
              type: 'steps',
              attributes: hash_including(name: 'Step name')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'steps',
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
