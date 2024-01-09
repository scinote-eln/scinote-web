# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::StepElements::StepElements::TextsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team, created_by: @user)
    @experiment = create(:experiment, :with_tasks, project: @project, created_by: @user)
    @task = @experiment.my_modules.first
    @protocol = create(:protocol, my_module: @task)
    @step = create(:step, protocol: @protocol)

    @valid_headers = {
      'Authorization': 'Bearer ' + generate_token(@user.id),
      'Content-Type': 'application/json'
    }
  end

  describe 'GET texts, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_texts_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when step is not found' do
      it 'renders 404' do
        get api_v2_team_project_experiment_task_protocol_step_texts_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: -1
        ), headers: @valid_headers

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET step_text, #show' do
    let(:step_text) { create(:step_text, step: @step) }

    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_text_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id,
          id: step_text.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST step_text, #create' do
    let(:action) do
      post(api_v2_team_project_experiment_task_protocol_step_texts_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id
      ), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'step_texts',
            attributes: {
             text: "<p>Hello!</p>"
            }
          }
        }
      end

      it 'creates new step_text' do
        expect { action }.to change { StepText.count }.by(1)
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
              type: 'step_texts',
              attributes: hash_including(text: '<p>Hello!</p>')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'step_texts',
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

  describe 'PATCH step_text, #update' do
    let(:step_text) { create(:step_text, step: @step) }
    let(:action) do
      patch(api_v2_team_project_experiment_task_protocol_step_text_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        id: step_text.id
      ), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'step_texts',
            attributes: {
              text: '<h1>Hello!</h1>'
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
              type: 'step_texts',
              attributes: hash_including(
                text: '<h1>Hello!</h1>'
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
            type: 'step_texts',
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

  describe 'DELETE step_text, #destroy' do
    let(:step_text) { create(:step_text, step: @step) }
    let(:action) do
      delete(api_v2_team_project_experiment_task_protocol_step_text_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        id: step_text.id
      ), headers: @valid_headers)
    end

    it 'deletes step_text' do
      action
      expect(response).to have_http_status(200)
      expect(StepText.where(id: step_text.id)).to_not exist
    end
  end
end
