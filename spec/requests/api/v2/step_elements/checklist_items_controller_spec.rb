# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::StepElements::ChecklistItemsController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team, created_by: @user)
    @experiment = create(:experiment, :with_tasks, project: @project)
    @task = @experiment.my_modules.first
    @protocol = create(:protocol, my_module: @task)
    @step = create(:step, protocol: @protocol)
    @checklist = create(:checklist, step: @step)

    @valid_headers = {
      'Authorization': 'Bearer ' + generate_token(@user.id),
      'Content-Type': 'application/json'
    }
  end

  describe 'GET checklist_items, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_checklist_items_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id,
          checklist_id: @checklist.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when checklist is not found' do
      it 'renders 404' do
        get api_v2_team_project_experiment_task_protocol_step_checklist_items_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id,
          checklist_id: -1
        ), headers: @valid_headers

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET checklist_item, #show' do
    let(:checklist_item) { create(:checklist_item, checklist: @checklist) }

    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_checklist_item_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id,
          checklist_id: @checklist.id,
          id: checklist_item.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST checklist_item, #create' do
    let(:action) do
      post(api_v2_team_project_experiment_task_protocol_step_checklist_items_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        checklist_id: @checklist.id
      ), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'checklist_items',
            attributes: {
              text: 'New checklist_item'
            }
          }
        }
      end

      it 'creates new checklist_item' do
        expect { action }.to change { ChecklistItem.count }.by(1)
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
              type: 'checklist_items',
              attributes: hash_including(text: 'New checklist_item')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'checklist_items',
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

  describe 'PATCH checklist_item, #update' do
    let(:checklist_item) { create(:checklist_item, checklist: @checklist) }
    let(:action) do
      patch(api_v2_team_project_experiment_task_protocol_step_checklist_item_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        checklist_id: @checklist.id,
        id: checklist_item.id
      ), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'checklist_items',
            attributes: {
              text: 'New checklist_item name'
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
              type: 'checklist_items',
              attributes: hash_including(
                text: 'New checklist_item name'
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
            type: 'checklist_items',
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

  describe 'DELETE checklist_item, #destroy' do
    let(:checklist_item) { create(:checklist_item, checklist: @checklist) }
    let(:action) do
      delete(api_v2_team_project_experiment_task_protocol_step_checklist_item_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        checklist_id: @checklist.id,
        id: checklist_item.id
      ), headers: @valid_headers)
    end

    it 'deletes checklist_item' do
      action
      expect(response).to have_http_status(200)
      expect(ChecklistItem.where(id: checklist_item.id)).to_not exist
    end
  end
end
