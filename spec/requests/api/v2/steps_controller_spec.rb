# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::StepsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team, created_by: @user)
    @experiment = create(:experiment, :with_tasks, project: @project, created_by: @user)
    @task = @experiment.my_modules.first

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  let(:protocol) { create :protocol, my_module: @task }
  let(:steps) { create_list(:step, 3, protocol: protocol) }
  let(:step) { steps.first }

  describe 'GET steps, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_steps_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: protocol.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when has valid params, with rendered RTE field' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_steps_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: protocol.id
        ), params: { render_rte: true }, headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when protocol is not found' do
      it 'renders 404' do
        get api_v2_team_project_experiment_task_protocol_steps_path(
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
        get api_v2_team_project_experiment_task_protocol_step_path(
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
  end

  describe 'POST step, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      post(api_v2_team_project_experiment_task_protocol_steps_path(
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
        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'steps',
              attributes: hash_not_including(:description)
            )
          )
        )
      end

      it 'sets the last_changed_by' do
        action

        expect(Step.find(json['data']['id']).last_modified_by_id).to be @user.id
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

  describe 'PATCH step, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      patch(
        api_v2_team_project_experiment_task_protocol_step_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: protocol.id,
          id: step.id
        ),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'steps',
            attributes: {
              name: 'New step name',
              description: 'New description about step'
            }
          }
        }
      end

      it 'returns status 200' do
        action

        expect(response).to have_http_status 200
      end

      it 'returns well formatted response' do
        action

        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'steps',
              attributes: hash_including(name: 'New step name')
            )
          )
        )
        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'steps',
              attributes: hash_not_including(:description)
            )
          )
        )
      end

      it 'sets the last_changed_by' do
        action
        expect(Step.find(json['data']['id']).last_modified_by_id).to be @user.id
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

  describe 'DELETE step, #destroy' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      delete(
        api_v2_team_project_experiment_task_protocol_step_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: protocol.id,
          id: step.id,
          data: {attributes: {name: 'Test'}, type: "steps"}
        ),
        headers: @valid_headers
      )
    end

    it 'deletes step' do
      action
      expect(response).to have_http_status(200)
      expect(Step.where(id: step.id)).to_not exist
    end
  end
end
