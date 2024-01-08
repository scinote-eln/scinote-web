# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::StepElements::ChecklistsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team, created_by: @user)
    @experiment = create(:experiment, :with_tasks, project: @project)
    @task = @experiment.my_modules.first
    @protocol = create(:protocol, my_module: @task)
    @step = create(:step, protocol: @protocol)
    @valid_headers = {
      'Authorization': 'Bearer ' + generate_token(@user.id),
      'Content-Type': 'application/json'
    }
  end

  describe 'GET checklists, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_checklists_path(
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
        get api_v2_team_project_experiment_task_protocol_step_checklists_path(
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

  describe 'GET checklist, #show' do
    let(:checklist) { create(:checklist, step: @step) }

    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_checklist_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id,
          id: checklist.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST checklist, #create' do
    let(:action) do
      post(api_v2_team_project_experiment_task_protocol_step_checklists_path(
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
            type: 'checklists',
            attributes: {
              name: 'New checklist'
            }
          }
        }
      end

      it 'creates new checklist' do
        expect { action }.to change { Checklist.count }.by(1)
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
              type: 'checklists',
              attributes: hash_including(name: 'New checklist')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'checklists',
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

  describe 'PATCH checklist, #update' do
    let(:checklist) { create(:checklist, step: @step) }
    let(:action) do
      patch(api_v2_team_project_experiment_task_protocol_step_checklist_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        id: checklist.id
      ), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'checklists',
            attributes: {
              name: 'New checklist name'
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
              type: 'checklists',
              attributes: hash_including(
                name: 'New checklist name'
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
            type: 'checklists',
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

  describe 'DELETE checklist, #destroy' do
    let(:checklist) { create(:checklist, step: @step) }
    let(:action) do
      delete(api_v2_team_project_experiment_task_protocol_step_checklist_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        id: checklist.id
      ), headers: @valid_headers)
    end

    it 'deletes checklist' do
      action
      expect(response).to have_http_status(200)
      expect(Checklist.where(id: checklist.id)).to_not exist
    end
  end
end
